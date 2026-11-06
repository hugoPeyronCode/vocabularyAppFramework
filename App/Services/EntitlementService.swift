import Foundation
import Observation
import OSLog
import SagaceCore
import StoreKit

@MainActor
protocol PremiumProviding: AnyObject {
    var isPremium: Bool { get }
}

/// Droits premium et achats par StoreKit 2 (`03_ARCHITECTURE.md` section 10).
/// Les identifiants v3 `Yearly`, `weekly` et `lifetime` restent reconnus ; la décision est dans `EntitlementRules`.
@MainActor @Observable
final class EntitlementService: PremiumProviding {
    enum PurchaseOutcome: Equatable {
        case purchased(productID: String)
        case pending
        case cancelled
    }

    enum PurchaseError: Error { case productUnavailable, unverified }

    private(set) var isPremium = false
    private(set) var products: [String: Product] = [:]
    private(set) var expirationDate: Date?

    /// `com.words.premiumAccess` relevé par la migration v3 (règle 5).
    var legacyPremiumFlag = false

    private let analytics: any Analytics
    private let now: () -> Date
    private var updates: Task<Void, Never>?
    /// Seul le rafraîchissement le plus récent fait foi : un plus ancien, plus lent, ne doit pas réécrire un état périmé.
    private var refreshGeneration = 0
    private let logger = Logger(subsystem: "com.cortex.VocabularyAppFramework", category: "entitlements")

    init(analytics: any Analytics, now: @escaping () -> Date = { .now }) {
        self.analytics = analytics
        self.now = now
    }

    /// Au lancement : écoute des transactions (renouvellements, remboursements, achats hors app), produits, droits.
    func start(legacyPremiumFlag: Bool) async {
        self.legacyPremiumFlag = legacyPremiumFlag
        if updates == nil {
            updates = Task { [weak self] in
                for await result in Transaction.updates {
                    if case .verified(let transaction) = result { await transaction.finish() }
                    await self?.refresh()
                }
            }
        }
        await loadProducts()
        await refresh()
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: EntitlementRules.paywallProductIDs)
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        } catch {
            logger.error("Produits indisponibles : \(error)")
        }
    }

    func refresh() async {
        refreshGeneration += 1
        let generation = refreshGeneration
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-debugPremium") {
            isPremium = true
            return
        }
        #endif
        var snapshots: [EntitlementSnapshot] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            snapshots.append(EntitlementSnapshot(
                productID: transaction.productID, expirationDate: transaction.expirationDate,
                isRevoked: transaction.revocationDate != nil
            ))
        }
        let hasAnyTransaction = snapshots.isEmpty ? await self.hasAnyTransaction() : true
        let premium = EntitlementRules.isPremium(snapshots, at: now(), hasAnyTransaction: hasAnyTransaction, legacyPremiumFlag: legacyPremiumFlag)
        guard generation == refreshGeneration else { return }
        if premium, snapshots.isEmpty {
            logger.notice("Premium accordé depuis la clé v3 com.words.premiumAccess, aucune transaction trouvée")
        }
        expirationDate = snapshots.compactMap(\.expirationDate).max()
        isPremium = premium
    }

    private func hasAnyTransaction() async -> Bool {
        for await result in Transaction.all {
            if case .verified(let transaction) = result, Rules.premiumProductIDs.contains(transaction.productID) { return true }
        }
        return false
    }

    /// Achat d'un produit du paywall. `perform` est l'action d'achat de SwiftUI (ou `product.purchase()` en test).
    func purchase(_ productID: String, perform: (Product) async throws -> Product.PurchaseResult) async throws -> PurchaseOutcome {
        guard let product = products[productID] else { throw PurchaseError.productUnavailable }
        switch try await perform(product) {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw PurchaseError.unverified }
            await transaction.finish()
            await refresh()
            analytics.track(.purchaseCompleted(productID: productID))
            return .purchased(productID: productID)
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    /// "Restaurer" : resynchronise avec l'App Store puis relit les droits.
    func restore() async throws {
        try await AppStore.sync()
        await refresh()
    }
}
