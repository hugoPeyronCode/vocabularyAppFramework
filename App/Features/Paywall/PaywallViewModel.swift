import Foundation
import Observation
import SagaceCore
import SagaceUI
import StoreKit

/// Paywall (PAY-01) : plans annuel et à vie, frise d'essai, rappel de fin d'essai activé par défaut.
@MainActor @Observable
final class PaywallViewModel {
    enum Plan: Hashable { case yearly, lifetime }

    let source: PaywallSource
    var plan: Plan = .yearly
    /// "Me rappeler avant la fin de l'essai", activé par défaut.
    var remindBeforeTrialEnds = true
    private(set) var isWorking = false
    var showsPurchaseError = false
    private(set) var didUnlock = false

    private let entitlements: EntitlementService
    private let haptics: any HapticPlaying
    private let analytics: any Analytics

    init(source: PaywallSource, entitlements: EntitlementService, haptics: any HapticPlaying, analytics: any Analytics) {
        self.source = source; self.entitlements = entitlements; self.haptics = haptics; self.analytics = analytics
    }

    var yearlyPrice: String? { entitlements.products[EntitlementRules.yearlyProductID]?.displayPrice }
    var lifetimePrice: String? { entitlements.products[EntitlementRules.lifetimeProductID]?.displayPrice }
    /// L'essai de 3 jours n'est proposé qu'une fois par compte Apple.
    var offersTrial: Bool { plan == .yearly && entitlements.isTrialEligible }
    var canPurchase: Bool { !isWorking && productID.flatMap { entitlements.products[$0] } != nil }

    private var productID: String? {
        switch plan {
        case .yearly: EntitlementRules.yearlyProductID
        case .lifetime: EntitlementRules.lifetimeProductID
        }
    }

    func onAppear() async {
        analytics.track(.paywallViewed(source: source.rawValue))
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
            let outcome = try await entitlements.purchase(productID, remindBeforeTrialEnds: offersTrial && remindBeforeTrialEnds, perform: perform)
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
