import Foundation
import Observation
import SagaceCore
import SagaceUI
import StoreKit

/// Paywall (PAY-01) : une seule offre, hebdomadaire sans essai ou à vie.
@MainActor @Observable
final class PaywallViewModel {
    enum Plan: Hashable { case weekly, lifetime }

    let source: PaywallSource
    var plan: Plan = .weekly
    private(set) var isWorking = false
    var showsPurchaseError = false
    private(set) var didUnlock = false

    private let entitlements: EntitlementService
    private let haptics: any HapticPlaying
    private let analytics: any Analytics

    init(source: PaywallSource, entitlements: EntitlementService, haptics: any HapticPlaying, analytics: any Analytics) {
        self.source = source; self.entitlements = entitlements; self.haptics = haptics; self.analytics = analytics
    }

    var weeklyPrice: String? { entitlements.products[EntitlementRules.weeklyProductID]?.displayPrice }
    var lifetimePrice: String? { entitlements.products[EntitlementRules.lifetimeProductID]?.displayPrice }
    var canPurchase: Bool { !isWorking && productID.flatMap { entitlements.products[$0] } != nil }

    private var productID: String? {
        switch plan {
        case .weekly: EntitlementRules.weeklyProductID
        case .lifetime: EntitlementRules.lifetimeProductID
        }
    }

    func onAppear() async {
        analytics.track(.paywallViewed(source: source.rawValue))
        await loadOffers()
    }

    /// Offres App Store ; rappelé au retour du réseau si elles n'ont pas pu être chargées.
    func loadOffers() async {
        if entitlements.products.isEmpty { await entitlements.loadProducts() }
    }

    func select(_ plan: Plan) {
        self.plan = plan
    }

    func purchase(perform: (Product) async throws -> Product.PurchaseResult) async {
        guard let productID, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let outcome = try await entitlements.purchase(productID, perform: perform)
            if case .purchased = outcome {
                haptics.play(.celebration)
                didUnlock = true
            }
        } catch {
            haptics.play(.error)
            showsPurchaseError = true
        }
    }

    func restore() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await entitlements.restore()
            if entitlements.isPremium {
                haptics.play(.success)
                didUnlock = true
            }
        } catch {
            showsPurchaseError = true
        }
    }
}
