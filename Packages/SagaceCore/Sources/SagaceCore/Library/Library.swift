import Foundation

/// Statut d'une fiche dans les listes (EXP-02) : nouveau, à retenir, maîtrisé.
public enum FicheStatus: String, Sendable, CaseIterable {
    case new, known, toLearn, mastered

    public init(progress: FicheProgress?) {
        guard let progress else { self = .new; return }
        if progress.review.masteredAt != nil { self = .mastered }
        else if progress.sorting == .toLearn { self = .toLearn }
        else if progress.sorting == .known { self = .known }
        else { self = .new }
    }
}

/// Raisons d'un signalement (DET-02) et suggestion de mot (EXP-03).
public enum ReportReason: String, Codable, Sendable, CaseIterable {
    case definition, example, typo, other
    /// "Proposer ce mot ?" depuis une recherche sans résultat.
    case suggestion
    /// Bêta : la fiche est jugée juste par le testeur.
    case confirmed
}

/// Listes de la bibliothèque (LIB-01, LIB-02, LIB-05). Pures, à partir de la progression.
public struct Library: Sendable {
    public let day: SagaceDay

    public init(day: SagaceDay = SagaceDay()) {
        self.day = day
    }

    public struct ToLearnItem: Equatable, Sendable {
        public let ficheID: String
        /// Jours avant la prochaine révision : 0 = aujourd'hui (ou en retard), 1 = demain.
        public let daysUntilReview: Int
    }

    /// LIB-01 : fiches "À retenir" non maîtrisées, par prochaine révision.
    public func toLearn(_ progress: some Sequence<FicheProgress>, at now: Date) -> [ToLearnItem] {
        progress
            .filter { $0.sorting == .toLearn && $0.review.isInReview }
            .sorted { ($0.review.nextReviewAt ?? .distantFuture, $0.ficheID) < ($1.review.nextReviewAt ?? .distantFuture, $1.ficheID) }
            .map { item in
                let days = item.review.nextReviewAt.map { max(0, day.days(from: now, to: $0)) } ?? 0
                return ToLearnItem(ficheID: item.ficheID, daysUntilReview: days)
            }
    }

    /// LIB-02 : fiches maîtrisées, la plus récente d'abord.
    public func mastered(_ progress: some Sequence<FicheProgress>) -> [FicheProgress] {
        progress
            .filter { $0.review.masteredAt != nil }
            .sorted { ($0.review.masteredAt ?? .distantPast) > ($1.review.masteredAt ?? .distantPast) }
    }

    public struct HistoryDay: Equatable, Sendable {
        public let day: Date
        public let fiches: [FicheProgress]
    }

    /// LIB-05 : fiches vues, groupées par journée (la plus récente d'abord), sur les `days` derniers jours.
    public func history(_ progress: some Sequence<FicheProgress>, at now: Date, days: Int) -> [HistoryDay] {
        let oldest = day.adding(days: -(days - 1), to: day.day(of: now))
        let seen = progress.compactMap { item -> (Date, FicheProgress)? in
            guard let lastSeen = item.lastSeenAt else { return nil }
            let seenDay = day.day(of: lastSeen)
            return seenDay >= oldest ? (seenDay, item) : nil
        }
        return Dictionary(grouping: seen, by: \.0)
            .map { HistoryDay(day: $0.key, fiches: $0.value.map(\.1).sorted { ($0.lastSeenAt ?? .distantPast) > ($1.lastSeenAt ?? .distantPast) }) }
            .sorted { $0.day > $1.day }
    }

    /// Il reste des fiches plus anciennes que la fenêtre affichée.
    public func hasOlderHistory(_ progress: some Sequence<FicheProgress>, at now: Date, days: Int) -> Bool {
        let oldest = day.adding(days: -(days - 1), to: day.day(of: now))
        return progress.contains { $0.lastSeenAt.map { day.day(of: $0) < oldest } ?? false }
    }
}
