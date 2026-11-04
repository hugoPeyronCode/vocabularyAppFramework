import Foundation
import Observation
import SagaceData

/// Sheets ouvertes depuis le feed (`03_ARCHITECTURE.md` section 6).
enum Sheet: Identifiable, Hashable {
    case explore, profile, stats, practice, day(Date)
    case fiche(String), share(String)
    case paywall(PaywallSource)

    var id: Self { self }
}

/// Points d'entrée du paywall (PAY-01).
enum PaywallSource: String, Hashable {
    case onboarding, crown, proBanner, endOfFreeBatch, lockedFiche, stats, reminders, voices, widgets
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
    var fullScreen: FullScreen?

    func open(_ sheet: Sheet) {
        self.sheet = sheet
    }
}
