import Foundation

/// Ce que les widgets ont fait depuis la dernière ouverture de l'app : réponses aux révisions, "À retenir",
/// fiches suivantes. Le widget écrit, l'app applique puis vide (la base SwiftData n'est ouverte que par l'app).
public struct WidgetInbox: Codable, Equatable, Sendable {
    public enum Action: Codable, Equatable, Sendable {
        case review(ficheID: String, correct: Bool, at: Date)
        case toLearn(ficheID: String, at: Date)
        case nextCard(at: Date)
    }

    /// Réponse affichée par le widget de révision, jusqu'à "Continuer".
    public struct Feedback: Codable, Equatable, Sendable {
        public let ficheID: String
        public let chosenIndex: Int
        public let isCorrect: Bool
    }

    public private(set) var actions: [Action] = []
    /// Fiches passées avec "Suivante", par widget (clé : famille, ou `allKey`).
    public private(set) var cardOffsets: [String: Int] = [:]
    public private(set) var feedback: Feedback?

    public static let allKey = "all"

    public init() {}

    public var answeredReviewIDs: Set<String> {
        Set(actions.compactMap { if case .review(let id, _, _) = $0 { id } else { nil } })
    }

    public var savedIDs: Set<String> {
        Set(actions.compactMap { if case .toLearn(let id, _) = $0 { id } else { nil } })
    }

    /// Répondre à une révision : une seule fois par fiche, l'explication reste affichée jusqu'à "Continuer".
    public mutating func answer(_ review: WidgetSnapshot.Review, choice: Int, at now: Date) {
        guard feedback == nil, !answeredReviewIDs.contains(review.ficheID) else { return }
        let correct = choice == review.correctIndex
        actions.append(.review(ficheID: review.ficheID, correct: correct, at: now))
        feedback = Feedback(ficheID: review.ficheID, chosenIndex: choice, isCorrect: correct)
    }

    public mutating func continueReview() {
        feedback = nil
    }

    public mutating func nextCard(key: String, at now: Date) {
        cardOffsets[key, default: 0] += 1
        actions.append(.nextCard(at: now))
    }

    public mutating func saveToLearn(_ ficheID: String, at now: Date) {
        guard !savedIDs.contains(ficheID) else { return }
        actions.append(.toLearn(ficheID: ficheID, at: now))
    }
}

/// État du widget de révision.
public enum ReviewDisplay: Equatable, Sendable {
    case question(WidgetSnapshot.Review)
    case feedback(WidgetSnapshot.Review, chosenIndex: Int, isCorrect: Bool)
    /// Plus rien à réviser depuis le widget ; `remaining` révisions dues restent à faire dans l'app.
    case done(remaining: Int)
}

public extension WidgetSnapshot {
    func reviewDisplay(_ inbox: WidgetInbox) -> ReviewDisplay {
        if let feedback = inbox.feedback, let review = reviews.first(where: { $0.ficheID == feedback.ficheID }) {
            return .feedback(review, chosenIndex: feedback.chosenIndex, isCorrect: feedback.isCorrect)
        }
        let answered = inbox.answeredReviewIDs
        if let next = reviews.first(where: { !answered.contains($0.ficheID) }) { return .question(next) }
        return .done(remaining: max(dueReviewCount - reviews.filter { answered.contains($0.ficheID) }.count, 0))
    }

    /// Fiche montrée par une entrée de la frise : on avance d'une fiche par entrée et par "Suivante".
    func card(for family: Family?, offset: Int) -> Card? {
        let cards = cards(for: family)
        guard !cards.isEmpty else { return nil }
        return cards[((offset % cards.count) + cards.count) % cards.count]
    }
}

/// Dates de la frise d'un widget de fiche, selon le rafraîchissement choisi (par défaut : une fois par jour, au nouveau lot).
public enum WidgetSchedule {
    public static func entryDates(_ rate: RefreshRate, from now: Date, day: SagaceDay) -> [Date] {
        let calendar = day.calendar
        switch rate {
        case .hourly:
            let hour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
            return [now] + (1..<Rules.widgetHourlyEntries).compactMap { calendar.date(byAdding: .hour, value: $0, to: hour) }
        case .twiceDaily:
            let next = day.nextBatch(after: now)
            let half = next.addingTimeInterval(-12 * 3_600)
            return [now] + (half > now ? [half, next] : [next])
        case .daily:
            return [now, day.nextBatch(after: now)]
        }
    }
}
