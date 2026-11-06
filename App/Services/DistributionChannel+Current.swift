import SagaceCore
import StoreKit

extension DistributionChannel {
    /// Lu dans la transaction de l'app : environnement sandbox = TestFlight. Sans réponse, App Store (brouillons masqués).
    static func current() async -> DistributionChannel {
        #if DEBUG
        return .development
        #else
        guard let result = try? await AppTransaction.shared else { return .appStore }
        switch result.unsafePayloadValue.environment {
        case .sandbox: return .testFlight
        case .xcode: return .development
        default: return .appStore
        }
        #endif
    }
}
