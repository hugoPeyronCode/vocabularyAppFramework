import Foundation
import Testing
@testable import SagaceCore

@Suite("Achats et onboarding")
struct PurchasesTests {
    let now = TestClock.date()

    @Test("Abonnements v3 et v4 reconnus : Yearly, weekly, lifetime", arguments: ["Yearly", "weekly", "lifetime"])
    func legacyProducts(productID: String) {
        let entitlement = EntitlementSnapshot(productID: productID, expirationDate: productID == "lifetime" ? nil : TestClock.date(days: 3))
        #expect(EntitlementRules.isPremium([entitlement], at: now, hasAnyTransaction: true, legacyPremiumFlag: false))
    }

    @Test("Expiré, remboursé ou produit inconnu : pas premium")
    func notPremium() {
        let expired = EntitlementSnapshot(productID: "Yearly", expirationDate: TestClock.date(days: -1))
        let revoked = EntitlementSnapshot(productID: "lifetime", isRevoked: true)
        let unknown = EntitlementSnapshot(productID: "coins", expirationDate: nil)
        #expect(!EntitlementRules.isPremium([expired, revoked, unknown], at: now, hasAnyTransaction: true, legacyPremiumFlag: false))
        #expect(!EntitlementRules.isPremium([], at: now, hasAnyTransaction: false, legacyPremiumFlag: false))
    }

    @Test("Règle 5 : clé v3 à vrai sans aucune transaction → premium ; avec une transaction ancienne → non")
    func legacyFlag() {
        #expect(EntitlementRules.isPremium([], at: now, hasAnyTransaction: false, legacyPremiumFlag: true))
        #expect(!EntitlementRules.isPremium([], at: now, hasAnyTransaction: true, legacyPremiumFlag: true))
    }

    @Test("Mini test : 5 questions, une par famille principale, au niveau intermédiaire si possible")
    func miniTest() throws {
        let repository = try ContentRepository(data: Data(contentsOf: SeedContent.fichesURL), visibility: .development)
        let questions = QuestionFactory(fiches: repository.fiches).miniTest(seed: 1)
        #expect(questions.count == Rules.miniTestLength)
        let families = questions.compactMap { repository.fiche(id: $0.ficheID)?.family }
        #expect(families == Rules.miniTestFamilies)
        #expect(questions.allSatisfy { $0.isWellFormed })
    }
}
