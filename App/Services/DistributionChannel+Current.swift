import SagaceCore
import StoreKit

extension DistributionChannel {
    /// Lu dans la transaction de l'app : environnement sandbox = TestFlight. Sans réponse en `Rules.storeKitLaunchTimeout`
    /// secondes, App Store (brouillons masqués) : `AppTransaction.shared` peut attendre indéfiniment sur un appareil.
    static func current() async -> DistributionChannel {
        #if DEBUG
        return .development
        #else
        guard let result = await value(within: Rules.storeKitLaunchTimeout, of: { try? await AppTransaction.shared }) ?? nil else {
            return .appStore
        }
        switch result.unsafePayloadValue.environment {
        case .sandbox: return .testFlight
        case .xcode: return .development
        default: return .appStore
        }
        #endif
    }
}
