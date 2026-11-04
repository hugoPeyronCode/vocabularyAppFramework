/// Événements analytics v4 (`03_ARCHITECTURE.md` section 11).
public enum AnalyticsEvent: Equatable, Sendable {
    public enum FicheOrigin: String, Sendable { case feed, widget, notification, explore }

    case ficheViewed(ficheID: String, family: Family, origin: FicheOrigin)
    case ficheSorted(ficheID: String, sorting: Sorting)
    case reviewAnswered(ficheID: String, box: Int, correct: Bool)
    case ficheMastered(ficheID: String, daysToMaster: Int)
    case dailyGoalCompleted(streak: Int)
    case migrationV3Completed(hadSavedWords: Bool, wasPremium: Bool)
    case errorReported(ficheID: String, reason: ReportReason)

    public var name: String {
        switch self {
        case .ficheViewed: "fiche_viewed"
        case .ficheSorted: "fiche_sorted"
        case .reviewAnswered: "review_answered"
        case .ficheMastered: "fiche_mastered"
        case .dailyGoalCompleted: "daily_goal_completed"
        case .migrationV3Completed: "migration_v3_completed"
        case .errorReported: "error_reported"
        }
    }

    public var properties: [String: String] {
        switch self {
        case let .ficheViewed(id, family, origin):
            ["fiche_id": id, "family": family.rawValue, "origin": origin.rawValue]
        case let .ficheSorted(id, sorting):
            ["fiche_id": id, "sorting": sorting == .known ? "known" : "to_learn"]
        case let .reviewAnswered(id, box, correct):
            ["fiche_id": id, "box": String(box), "correct": String(correct)]
        case let .ficheMastered(id, days):
            ["fiche_id": id, "days_to_master": String(days)]
        case let .dailyGoalCompleted(streak):
            ["streak": String(streak)]
        case let .migrationV3Completed(hadSavedWords, wasPremium):
            ["had_saved_words": String(hadSavedWords), "was_premium": String(wasPremium)]
        case let .errorReported(id, reason):
            ["fiche_id": id, "reason": reason.rawValue]
        }
    }
}

/// Émetteur d'événements. Implémentation console en M1, outil définitif en M7 (`OPEN_QUESTIONS.md` n° 5).
public protocol Analytics: Sendable {
    func track(_ event: AnalyticsEvent)
}
