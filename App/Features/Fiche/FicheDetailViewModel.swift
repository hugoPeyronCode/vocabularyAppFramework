import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI

/// Fiche détaillée (DET-01), gratuite en entier.
@MainActor @Observable
final class FicheDetailViewModel {
    let fiche: Fiche
    let familyName: String
    let sections: [FicheSection]
    private(set) var sorting: Sorting?

    private let content: ContentRepository
    private let store: any ProgressStoring
    private let audio: any Speaking
    private let haptics: any HapticPlaying
    private let analytics: any Analytics
    private let origin: AnalyticsEvent.FicheOrigin?
    private let now: () -> Date

    /// - Parameter origin: provenance à journaliser ; `nil` si la fiche a déjà été comptée (ouverte depuis le feed).
    init(
        fiche: Fiche, familyName: String, content: ContentRepository, store: any ProgressStoring, audio: any Speaking,
        haptics: any HapticPlaying, analytics: any Analytics, origin: AnalyticsEvent.FicheOrigin?, now: @escaping () -> Date
    ) {
        self.fiche = fiche; self.familyName = familyName; self.content = content; self.store = store
        self.audio = audio; self.haptics = haptics; self.analytics = analytics; self.origin = origin; self.now = now
        self.sections = FicheSection.visible(for: fiche)
    }

    func onAppear() {
        sorting = store.allProgress()[fiche.id]?.sorting
        if let origin {
            store.markSeen(fiche.id, at: now())
            store.save()
            analytics.track(.ficheViewed(ficheID: fiche.id, family: fiche.family, origin: origin))
        }
    }

    func speak() {
        audio.speak(fiche.headword, language: fiche.language)
    }

    func sort(_ sorting: Sorting) {
        let result = store.sort(fiche.id, as: sorting, at: now())
        self.sorting = sorting
        analytics.track(.ficheSorted(ficheID: fiche.id, sorting: sorting))
        haptics.play(result.goalJustReached ? .success : .light)
        if result.goalJustReached {
            analytics.track(.dailyGoalCompleted(streak: StreakCalculator().summary(of: store.activity(), at: now()).current))
        }
    }

    /// Fiche d'un synonyme ou d'une confusion, si elle existe dans le pack.
    func ficheID(for word: String) -> String? {
        content.fiche(headword: word).map(\.id).flatMap { $0 == fiche.id ? nil : $0 }
    }
}
