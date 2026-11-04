import SwiftUI
import UIKit

/// Retours haptiques de Sagace (`02_DESIGN_SYSTEM.md` section 8).
public enum HapticEvent: Sendable, CaseIterable {
    /// Changement de mot, d'onglet ou de chip.
    case selection
    /// Je savais, À retenir, boutons.
    case light
    /// Sélection d'une option.
    case soft
    /// Perte d'une vie.
    case heavy
    /// Bonne réponse, objectif atteint.
    case success
    /// Mauvaise réponse.
    case error
    /// Fin de session, nouveau niveau, mot maîtrisé : `.success` puis `.light`.
    case celebration
}

/// Ce que les view models et les composants utilisent, pour pouvoir passer un faux en test.
@MainActor
public protocol HapticPlaying: AnyObject, Sendable {
    func play(_ event: HapticEvent)
}

@MainActor
public final class HapticsService: HapticPlaying {
    /// Instance partagée, valeur par défaut de l'environnement.
    public nonisolated static let shared = HapticsService()

    /// Réglage "Retour haptique", activé par défaut.
    public var isEnabled = true

    private lazy var selection = UISelectionFeedbackGenerator()
    private lazy var light = UIImpactFeedbackGenerator(style: .light)
    private lazy var soft = UIImpactFeedbackGenerator(style: .soft)
    private lazy var heavy = UIImpactFeedbackGenerator(style: .heavy)
    private lazy var notification = UINotificationFeedbackGenerator()

    public nonisolated init() {}

    public func play(_ event: HapticEvent) {
        guard isEnabled else { return }
        switch event {
        case .selection: selection.selectionChanged()
        case .light: light.impactOccurred()
        case .soft: soft.impactOccurred()
        case .heavy: heavy.impactOccurred()
        case .success: notification.notificationOccurred(.success)
        case .error: notification.notificationOccurred(.error)
        case .celebration:
            notification.notificationOccurred(.success)
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(180))
                guard let self, self.isEnabled else { return }
                self.light.impactOccurred()
            }
        }
    }
}

public extension EnvironmentValues {
    /// Service haptique injecté une fois à la racine de l'app.
    @Entry var haptics: any HapticPlaying = HapticsService.shared
}
