import Foundation
import Observation
import SagaceCore
import SagaceData
import SwiftData

/// Sheets ouvertes depuis le feed (`03_ARCHITECTURE.md` section 6).
enum Sheet: Identifiable, Hashable {
    case explore, profile, stats, practice, day(Date)
    case fiche(String), share(String)
    case session(PracticeRequest), challenge(ChallengeState.Kind), levelTest
    case paywall(PaywallSource)

    var id: Self { self }
}

/// Ce qu'on travaille dans une session (PRA-02).
enum PracticeRequest: Hashable {
    /// Un des 6 jeux, sur tout le pack.
    case game(GameType)
    /// "S'entraîner sur cette famille" (EXP-02).
    case family(Family)
    /// Fiches d'un thème ou d'une collection.
    case fiches([String])
    /// "Réviser maintenant" (LIB-01) : hors limite gratuite.
    case review([String])

    var mode: PracticeMode {
        switch self {
        case .game(let game): PracticeMode(rawValue: game.rawValue) ?? .mixed
        case .family, .fiches: .mixed
        case .review: .review
        }
    }
}

/// Points d'entrée du paywall (PAY-01).
enum PaywallSource: String, Hashable, Identifiable {
    case onboarding, crown, proBanner, endOfFreeBatch, lockedFiche, stats, reminders, voices, widgets
    var id: Self { self }
}

/// Sous-pages poussées dans le `NavigationStack` d'une sheet.
enum AppRoute: Hashable {
    case fiche(String)
    case topic(TopicKind)
    case toLearn, mastered, collections, ownWords, history, reports, editFollows
    case collection(PersistentIdentifier)
}

/// Famille ou thème (EXP-02).
enum TopicKind: Hashable {
    case family(Family)
    case theme(String)
}

enum FullScreen: Identifiable, Equatable {
    case migration(V3MigrationReport, isPremium: Bool)

    var id: String {
        switch self {
        case .migration: "migration"
        }
    }
}

@MainActor @Observable
final class AppRouter {
    var sheet: Sheet?
    /// Paywall par-dessus une sheet ouverte (verrou PRO dans Explorer, la fiche, les stats…).
    var stackedPaywall: PaywallSource?
    var fullScreen: FullScreen?

    func open(_ sheet: Sheet) {
        self.sheet = sheet
    }

    /// Ouvre l'action si premium, sinon le paywall par-dessus la sheet courante.
    func requirePremium(_ source: PaywallSource, isPremium: Bool, then action: () -> Void) {
        if isPremium { action() } else { stackedPaywall = source }
    }
}
