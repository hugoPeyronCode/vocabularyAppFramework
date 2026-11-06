import Foundation
import Network
import Observation

/// Connexion réseau. Tout fonctionne hors ligne (contenu embarqué) ; seuls les liens externes et les offres
/// du paywall en dépendent (`01_SCREENS.md` section I).
@MainActor @Observable
final class Connectivity {
    private(set) var isOnline = true
    private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: DispatchQueue(label: "com.cortex.VocabularyAppFramework.connectivity"))
    }
}
