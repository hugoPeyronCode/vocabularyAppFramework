import Foundation
import OSLog
import SagaceCore
import SagaceData
import WidgetKit

/// Pont entre l'app et ses widgets (`03_ARCHITECTURE.md` section 9) : écrit le snapshot dans l'App Group,
/// applique ce que les widgets ont fait (révisions, "À retenir") et recharge leurs frises.
/// Seule l'app ouvre la base SwiftData ; les widgets passent par la boîte d'envoi.
@MainActor
final class WidgetBridge {
    private let files: WidgetStore?
    private let progress: any ProgressStoring
    private let library: any LibraryStoring
    private let entitlements: any PremiumProviding
    private let analytics: any Analytics
    private let day: SagaceDay
    private let now: () -> Date
    private let logger = Logger(subsystem: "com.cortex.VocabularyAppFramework", category: "widgets")
    var content: ContentRepository?

    init(files: WidgetStore? = .shared, progress: any ProgressStoring, library: any LibraryStoring, entitlements: any PremiumProviding,
         analytics: any Analytics, day: SagaceDay, now: @escaping () -> Date) {
        self.files = files; self.progress = progress; self.library = library; self.entitlements = entitlements
        self.analytics = analytics; self.day = day; self.now = now
    }

    /// Dernier snapshot écrit (aperçus de WID-01).
    var snapshot: WidgetSnapshot? { files?.readSnapshot() }

    /// Applique les gestes faits sur les widgets. Renvoie `true` si la progression a changé.
    @discardableResult
    func applyInbox() -> Bool {
        guard let files else { return false }
        let inbox = files.drainInbox()
        var changed = false
        for action in inbox.actions {
            switch action {
            case let .review(ficheID, correct, at):
                analytics.track(.widgetInteraction(kind: .revision, action: .answer))
                // Déjà révisée dans l'app entre-temps : la réponse du widget ne compte pas deux fois.
                guard progress.allProgress()[ficheID]?.review.isDue(at: at) == true else { continue }
                let result = progress.answerReview(ficheID, correct: correct, at: at)
                analytics.track(.reviewAnswered(ficheID: ficheID, box: result.previousBox, correct: correct))
                if result.outcome == .mastered {
                    analytics.track(.ficheMastered(ficheID: ficheID, daysToMaster: result.daysToMaster ?? 0))
                }
                changed = true
            case let .toLearn(ficheID, at):
                analytics.track(.widgetInteraction(kind: .ficheDuJour, action: .toLearn))
                guard progress.allProgress()[ficheID]?.sorting == nil else { continue }
                _ = progress.sort(ficheID, as: .toLearn, at: at)
                analytics.track(.ficheSorted(ficheID: ficheID, sorting: .toLearn))
                changed = true
            case .nextCard:
                analytics.track(.widgetInteraction(kind: .ficheDuJour, action: .next))
            }
        }
        if changed { progress.save() }
        return changed
    }

    /// Réécrit le snapshot et recharge les widgets.
    func refresh() {
        guard let files, let content else { return }
        let input = WidgetSnapshotBuilder.Input(
            fiches: content.fiches, progress: progress.allProgress(), profile: FeedProfile(store: progress, library: library),
            isPremium: entitlements.isPremium, dailyGoal: progress.preferences.dailyGoal, activity: progress.activity()
        )
        let snapshot = WidgetSnapshotBuilder(day: day).build(
            input, at: now(), grammar: { String(localized: $0.grammarLabel) }, gameTitle: { String(localized: $0.title) }
        )
        files.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        logger.info("Snapshot des widgets : \(snapshot.cards.count) fiches, \(snapshot.reviews.count) révisions")
    }
}
