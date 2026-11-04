import Foundation

/// Un droit d'achat tel que StoreKit le décrit, réduit à ce qui décide du premium.
public struct EntitlementSnapshot: Equatable, Sendable {
    public let productID: String
    public let expirationDate: Date?
    public let isRevoked: Bool

    public init(productID: String, expirationDate: Date? = nil, isRevoked: Bool = false) {
        self.productID = productID; self.expirationDate = expirationDate; self.isRevoked = isRevoked
    }
}

/// Règles d'accès premium (`04_MIGRATION.md` section 5, `03_ARCHITECTURE.md` section 10).
public enum EntitlementRules {
    public static let yearlyProductID = "Yearly"
    public static let lifetimeProductID = "lifetime"
    /// Abonnement hebdomadaire v3, retiré de la vente mais toujours reconnu.
    public static let weeklyProductID = "weekly"
    /// Produits proposés par le paywall, dans l'ordre d'affichage.
    public static let paywallProductIDs = [yearlyProductID, lifetimeProductID]

    /// Premium si un droit actif porte sur un produit premium (dont `Yearly`, `weekly`, `lifetime` de la v3).
    /// Règle 5 : aucune transaction connue de StoreKit mais clé v3 `com.words.premiumAccess` à vrai → premium.
    public static func isPremium(_ entitlements: [EntitlementSnapshot], at now: Date, hasAnyTransaction: Bool, legacyPremiumFlag: Bool) -> Bool {
        let active = entitlements.contains { entitlement in
            Rules.premiumProductIDs.contains(entitlement.productID)
                && !entitlement.isRevoked
                && (entitlement.expirationDate.map { $0 > now } ?? true)
        }
        return active || (legacyPremiumFlag && !hasAnyTransaction)
    }
}

/// Rappel de fin d'essai, 24 h avant la fin (activé par défaut sur le paywall).
public enum TrialReminder {
    public static func date(trialStart: Date, trialDays: Int = Rules.trialDays, calendar: Calendar = .current) -> Date {
        let end = calendar.date(byAdding: .day, value: trialDays, to: trialStart) ?? trialStart
        return end.addingTimeInterval(-TimeInterval(Rules.trialReminderHoursBeforeEnd) * 3_600)
    }
}

public extension QuestionFactory {
    /// Mini test d'onboarding (ONB-06) : une question par famille principale, niveau intermédiaire.
    func miniTest(seed: UInt64) -> [Question] {
        var rng = SeededGenerator(seed: seed)
        var used = Set<String>()
        return Rules.miniTestFamilies.compactMap { family in
            let candidates = allFiches
                .filter { $0.family == family && !used.contains($0.id) }
                .sorted { (abs($0.level - Rules.miniTestQuestionLevel.rawValue), $0.id) < (abs($1.level - Rules.miniTestQuestionLevel.rawValue), $1.id) }
            for fiche in candidates {
                for game in [GameType.preferred(for: family)] + GameType.allCases {
                    if let question = question(for: fiche, game: game, rng: &rng) {
                        used.insert(fiche.id)
                        return question
                    }
                }
            }
            return nil
        }
    }
}
