import Foundation

/// Position d'une fiche dans les boîtes de Leitner.
public struct ReviewState: Equatable, Sendable {
    /// 0 = hors révision, 1…4 = boîtes.
    public var box: Int
    public var nextReviewAt: Date?
    public var masteredAt: Date?

    public init(box: Int = 0, nextReviewAt: Date? = nil, masteredAt: Date? = nil) {
        self.box = box; self.nextReviewAt = nextReviewAt; self.masteredAt = masteredAt
    }

    public var isInReview: Bool { box > 0 && masteredAt == nil }

    public func isDue(at date: Date) -> Bool {
        guard isInReview, let nextReviewAt else { return false }
        return nextReviewAt <= date
    }
}

/// Résultat d'une révision, pour le texte et l'haptique de FEED-02 et FEED-03.
public enum ReviewOutcome: Equatable, Sendable {
    /// Bonne réponse : la fiche monte en `box`, prochaine révision dans `days` jours.
    case promoted(box: Int, nextInDays: Int)
    /// Bonne réponse en boîte 4 : mot maîtrisé.
    case mastered
    /// Mauvaise réponse : retour en boîte 1.
    case reset(nextInDays: Int)
}

/// Révisions espacées (Leitner), `03_ARCHITECTURE.md` section 7.
public struct ReviewScheduler: Sendable {
    public let day: SagaceDay

    public init(day: SagaceDay = SagaceDay()) {
        self.day = day
    }

    /// "À retenir" : boîte 1, révision demain.
    public func startLearning(at now: Date) -> ReviewState {
        ReviewState(box: 1, nextReviewAt: dueDate(afterDays: Rules.reviewIntervalDays(forBox: 1)!, from: now))
    }

    public func answer(_ state: ReviewState, correct: Bool, at now: Date) -> (ReviewState, ReviewOutcome) {
        guard correct else {
            let days = Rules.reviewIntervalDays(forBox: 1)!
            return (ReviewState(box: 1, nextReviewAt: dueDate(afterDays: days, from: now)), .reset(nextInDays: days))
        }
        if state.box >= Rules.maxBox {
            return (ReviewState(box: 0, nextReviewAt: nil, masteredAt: now), .mastered)
        }
        let box = max(state.box, 1) + 1
        let days = Rules.reviewIntervalDays(forBox: box)!
        return (ReviewState(box: box, nextReviewAt: dueDate(afterDays: days, from: now)), .promoted(box: box, nextInDays: days))
    }

    /// Une révision "dans n jours" est due dès le début de la journée Sagace concernée.
    private func dueDate(afterDays days: Int, from now: Date) -> Date {
        day.start(of: day.adding(days: days, to: day.day(of: now)))
    }
}
