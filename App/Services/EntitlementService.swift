import Foundation
import Observation
import OSLog
import SagaceCore
import StoreKit

@MainActor
protocol PremiumProviding: AnyObject {
    var isPremium: Bool { get }
}

/// Droits premium par StoreKit 2. Version minimale du jalon M1 (lecture seule) ; achat et paywall arrivent en M4.
@MainActor @Observable
final class EntitlementService: PremiumProviding {
    private(set) var isPremium = false
    private let logger = Logger(subsystem: "com.cortex.VocabularyAppFramework", category: "entitlements")

    /// - Parameter legacyPremiumFlag: `com.words.premiumAccess` relevé par la migration v3.
    func refresh(legacyPremiumFlag: Bool) async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-debugPremium") {
            isPremium = true
            return
        }
        #endif
        var hasActive = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               Rules.premiumProductIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                hasActive = true
            }
        }
        if hasActive {
            isPremium = true
            return
        }
        // Règle 5 de 04_MIGRATION.md : aucun achat connu de StoreKit mais clé v3 à vrai, on accorde le premium.
        if legacyPremiumFlag, await !hasAnyTransaction() {
            logger.notice("Premium accordé depuis la clé v3 com.words.premiumAccess, aucune transaction trouvée")
            isPremium = true
            return
        }
        isPremium = false
    }

    private func hasAnyTransaction() async -> Bool {
        for await result in Transaction.all {
            if case .verified(let transaction) = result, Rules.premiumProductIDs.contains(transaction.productID) { return true }
        }
        return false
    }
}
