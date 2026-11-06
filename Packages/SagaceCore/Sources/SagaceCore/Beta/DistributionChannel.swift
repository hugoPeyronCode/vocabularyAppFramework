import Foundation

/// Où tourne l'app : build de développement, bêta TestFlight ou App Store.
public enum DistributionChannel: String, Sendable {
    case development, testFlight, appStore

    /// Les brouillons ne sortent pas sur l'App Store ; en bêta, les testeurs sont les relecteurs (`05_CONTENT.md` 3.7).
    public var contentVisibility: ContentRepository.Visibility {
        self == .appStore ? .production : .development
    }

    /// Boutons « Juste » / « À corriger » sur chaque fiche et envoi des relectures.
    public var showsBetaReview: Bool {
        self != .appStore
    }
}
