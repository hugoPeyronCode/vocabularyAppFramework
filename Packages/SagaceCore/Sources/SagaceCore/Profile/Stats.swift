import Foundation

/// Carte 2 × 2 de STA-02 : fiches vues, à retenir, maîtrisées, sessions.
public struct ProgressSummary: Equatable, Sendable {
    public let seen: Int
    public let toLearn: Int
    public let mastered: Int
    public let sessions: Int

    /// - Parameter fiches: identifiants des fiches retenues par le filtre (famille), `nil` = toutes.
    public init(progress: [FicheProgress], sessions: Int, fiches: Set<String>? = nil) {
        let filtered = fiches.map { ids in progress.filter { ids.contains($0.ficheID) } } ?? progress
        self.seen = filtered.filter { $0.firstSeenAt != nil }.count
        self.toLearn = filtered.filter { $0.sorting == .toLearn && $0.review.isInReview }.count
        self.mastered = filtered.filter { $0.review.masteredAt != nil }.count
        self.sessions = sessions
    }
}

/// Calendrier du mois (STA-01) : cercle plein = objectif atteint, contour = activité partielle.
public struct MonthCalendar: Equatable, Sendable {
    public enum DayState: Equatable, Sendable { case none, partial, perfect, future }

    public struct Day: Equatable, Sendable, Identifiable {
        public let date: Date
        public let number: Int
        public let state: DayState
        public var id: Date { date }
    }

    /// Cases vides avant le 1er (semaine commençant le lundi).
    public let leadingBlanks: Int
    public let days: [Day]

    public init(month date: Date, activity: [DayActivity], today: Date, day sagaceDay: SagaceDay) {
        let calendar = sagaceDay.calendar
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let byDay = Dictionary(activity.map { (calendar.startOfDay(for: $0.day), $0) }, uniquingKeysWith: { first, _ in first })
        leadingBlanks = (calendar.component(.weekday, from: start) + 5) % 7
        days = (0..<count).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let state: DayState
            if day > today { state = .future }
            else if let activity = byDay[day], activity.goalReached { state = .perfect }
            else if let activity = byDay[day], activity.isActive { state = .partial }
            else { state = .none }
            return Day(date: day, number: offset + 1, state: state)
        }
    }
}

/// Succès v4 (STA-03), identifiants de `03_ARCHITECTURE.md` section 7.
public enum AchievementID: String, CaseIterable, Sendable {
    case serie3 = "serie_3", serie7 = "serie_7", serie30 = "serie_30"
    case maitrise10 = "maitrise_10", maitrise50 = "maitrise_50", maitrise100 = "maitrise_100"
    case testExpert = "test_expert"
    /// Au moins une fiche triée dans chaque famille.
    case toutesFamilles = "toutes_familles"
    /// 20 bonnes réponses en Rush.
    case rush20 = "rush_20"
}

public struct AchievementContext: Equatable, Sendable {
    public var longestStreak: Int
    public var mastered: Int
    public var bestTestLevel: Level?
    public var sortedFamilies: Set<Family>
    public var bestRush: Int

    public init(longestStreak: Int = 0, mastered: Int = 0, bestTestLevel: Level? = nil, sortedFamilies: Set<Family> = [], bestRush: Int = 0) {
        self.longestStreak = longestStreak; self.mastered = mastered; self.bestTestLevel = bestTestLevel
        self.sortedFamilies = sortedFamilies; self.bestRush = bestRush
    }
}

public enum AchievementRules {
    public static func unlocked(_ context: AchievementContext) -> Set<AchievementID> {
        Set(AchievementID.allCases.filter { id in
            switch id {
            case .serie3: context.longestStreak >= 3
            case .serie7: context.longestStreak >= 7
            case .serie30: context.longestStreak >= 30
            case .maitrise10: context.mastered >= 10
            case .maitrise50: context.mastered >= 50
            case .maitrise100: context.mastered >= 100
            case .testExpert: context.bestTestLevel == .expert
            case .toutesFamilles: context.sortedFamilies.isSuperset(of: Family.allCases)
            case .rush20: context.bestRush >= 20
            }
        })
    }
}
