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
    /// Bêta : boutons « Juste » / « À corriger » en bas de la fiche.
    let showsBetaReview: Bool
    private(set) var isConfirmed = false

    private let content: ContentRepository
    private let store: any ProgressStoring
    private let library: any LibraryStoring
    private let audio: any Speaking
    private let haptics: any HapticPlaying
    private let analytics: any Analytics
    private let origin: AnalyticsEvent.FicheOrigin?
    private let now: () -> Date

    /// - Parameter origin: provenance à journaliser ; `nil` si la fiche a déjà été comptée (ouverte depuis le feed).
    init(
        fiche: Fiche, familyName: String, content: ContentRepository, store: any ProgressStoring, library: any LibraryStoring,
        audio: any Speaking, haptics: any HapticPlaying, analytics: any Analytics, origin: AnalyticsEvent.FicheOrigin?,
        showsBetaReview: Bool = false, now: @escaping () -> Date
    ) {
        self.fiche = fiche; self.familyName = familyName; self.content = content; self.store = store; self.library = library
        self.audio = audio; self.haptics = haptics; self.analytics = analytics; self.origin = origin
        self.showsBetaReview = showsBetaReview; self.now = now
        self.sections = FicheSection.visible(for: fiche)
    }

    func onAppear() {
        sorting = store.allProgress()[fiche.id]?.sorting
        if showsBetaReview { isConfirmed = library.confirmedFicheIDs().contains(fiche.id) }
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

    /// Bêta : la fiche est jugée juste.
    func confirm() {
        guard !isConfirmed else { return }
        library.confirm(ficheID: fiche.id)
        isConfirmed = true
        haptics.play(.success)
    }

    /// Fiche d'un synonyme ou d'une confusion, si elle existe dans le pack.
    func ficheID(for word: String) -> String? {
        content.fiche(headword: word).map(\.id).flatMap { $0 == fiche.id ? nil : $0 }
    }
}
