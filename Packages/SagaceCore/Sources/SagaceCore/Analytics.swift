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
    case practiceStarted(mode: PracticeMode)
    case practiceCompleted(mode: PracticeMode, score: Int, total: Int)
    case levelTestCompleted(score: Int, level: Level)
    case onboardingStepViewed(step: String)
    case onboardingCompleted(miniTestScore: Int?, dailyGoal: Int, notificationsGranted: Bool)
    case paywallViewed(source: String)
    case purchaseCompleted(productID: String)
    case notificationOpened(reminderSource: String)

    public var name: String {
        switch self {
        case .ficheViewed: "fiche_viewed"
        case .ficheSorted: "fiche_sorted"
        case .reviewAnswered: "review_answered"
        case .ficheMastered: "fiche_mastered"
        case .dailyGoalCompleted: "daily_goal_completed"
        case .migrationV3Completed: "migration_v3_completed"
        case .errorReported: "error_reported"
        case .practiceStarted: "practice_started"
        case .practiceCompleted: "practice_completed"
        case .levelTestCompleted: "level_test_completed"
        case .onboardingStepViewed: "onboarding_step_viewed"
        case .onboardingCompleted: "onboarding_completed"
        case .paywallViewed: "paywall_viewed"
        case .purchaseCompleted: "purchase_completed"
        case .notificationOpened: "notification_opened"
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
        case let .practiceStarted(mode):
            ["mode": mode.rawValue]
        case let .practiceCompleted(mode, score, total):
            ["mode": mode.rawValue, "score": String(score), "total": String(total)]
        case let .levelTestCompleted(score, level):
            ["score": String(score), "level": String(level.rawValue)]
        case let .onboardingStepViewed(step):
            ["step": step]
        case let .onboardingCompleted(score, goal, granted):
            ["mini_test_score": score.map(String.init) ?? "", "daily_goal": String(goal), "notifications_granted": String(granted)]
        case let .paywallViewed(source):
            ["source": source]
        case let .purchaseCompleted(productID):
            ["product_id": productID]
        case let .notificationOpened(source):
            ["reminder_source": source]
        }
    }
}

/// Émetteur d'événements. Implémentation console en M1, outil définitif en M7 (`OPEN_QUESTIONS.md` n° 5).
public protocol Analytics: Sendable {
    func track(_ event: AnalyticsEvent)
}
