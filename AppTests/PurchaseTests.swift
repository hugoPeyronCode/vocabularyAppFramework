import Foundation
import SagaceCore
import StoreKit
import StoreKitTest
import Testing
@testable import VocabularyAppFramework

/// Achats en environnement StoreKit local (`Config/Sagace.storekit`), sans interface ni compte.
@MainActor
@Suite("Achats (StoreKit local)", .serialized)
struct PurchaseTests {
    let session: SKTestSession
    let analytics = RecordingAnalytics()

    init() throws {
        session = try SKTestSession(contentsOf: RepoFiles.storeKitConfiguration)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.askToBuyEnabled = false
    }

    private func makeService(legacyPremiumFlag: Bool = false) async -> EntitlementService {
        let service = EntitlementService(analytics: analytics)
        await service.start(legacyPremiumFlag: legacyPremiumFlag)
        return service
    }

    private let buy: (Product) async throws -> Product.PurchaseResult = { try await $0.purchase() }

    /// Un remboursement ou une expiration arrive par `Transaction.updates`, en quelques centaines de millisecondes.
    private func waitUntilNotPremium(_ service: EntitlementService) async throws {
        for _ in 0..<50 where service.isPremium {
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    @Test("Produits du paywall chargés : hebdomadaire et à vie, sans essai")
    func products() async {
        let service = await makeService()
        #expect(Set(service.products.keys) == ["weekly", "lifetime"])
        #expect(service.products["weekly"]?.subscription?.introductoryOffer == nil)
        #expect(!service.isPremium)
    }

    @Test("Achat hebdomadaire : premium immédiat")
    func weekly() async throws {
        let service = await makeService()
        let outcome = try await service.purchase("weekly", perform: buy)
        #expect(outcome == .purchased(productID: "weekly"))
        #expect(service.isPremium)
        #expect(analytics.events == [.purchaseCompleted(productID: "weekly")])
    }

    @Test("Achat à vie : premium")
    func lifetime() async throws {
        let service = await makeService()
        let outcome = try await service.purchase("lifetime", perform: buy)
        #expect(outcome == .purchased(productID: "lifetime"))
        #expect(service.isPremium)
    }

    @Test("Abonné annuel de Words v3 (Yearly, retiré de la vente) reconnu comme premium")
    func legacyYearly() async throws {
        _ = try await session.buyProduct(identifier: "Yearly")
        let service = await makeService()
        #expect(service.isPremium)
    }

    @Test("Abonné weekly de Words v3 reconnu comme premium")
    func legacyWeekly() async throws {
        _ = try await session.buyProduct(identifier: "weekly")
        let service = await makeService()
        #expect(service.isPremium)
    }

    @Test("Abonnement expiré ou annulé : plus premium")
    func expiredSubscription() async throws {
        let service = await makeService()
        _ = try await service.purchase("weekly", perform: buy)
        #expect(service.isPremium)
        try session.expireSubscription(productIdentifier: "weekly")
        try await waitUntilNotPremium(service)
        #expect(!service.isPremium)
    }

    @Test("Achat à vie remboursé : plus premium")
    func refundedLifetime() async throws {
        let transaction = try await session.buyProduct(identifier: "lifetime")
        let service = await makeService()
        #expect(service.isPremium)
        try session.refundTransaction(identifier: UInt(transaction.id))
        try await waitUntilNotPremium(service)
        #expect(!service.isPremium)
    }

    @Test("Restaurer : un achat fait ailleurs est retrouvé")
    func restore() async throws {
        let service = await makeService()
        #expect(!service.isPremium)
        _ = try await session.buyProduct(identifier: "lifetime")
        try await service.restore()
        #expect(service.isPremium)
    }

    @Test("Achat interrompu par l'utilisateur : rien ne change")
    func userCancelled() async throws {
        let service = await makeService()
        let outcome = try await service.purchase("weekly") { _ in .userCancelled }
        #expect(outcome == .cancelled)
        #expect(!service.isPremium)
    }

    @Test("Clé v3 com.words.premiumAccess sans aucune transaction : premium (règle 5)")
    func legacyFlag() async {
        let service = await makeService(legacyPremiumFlag: true)
        #expect(service.isPremium)
    }
}
