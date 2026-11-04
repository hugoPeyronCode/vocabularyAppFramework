import Foundation
import SagaceCore
import SwiftData

// État utilisateur (`03_ARCHITECTURE.md` section 4). Les valeurs par défaut sont celles de la spec.

@Model public final class UserProfile {
    public var firstName: String?
    public var ageRange: AgeRange?
    public var attribution: AttributionSource?
    public var goals: [LearningGoal]
    /// 1 à 5, fixé par l'onboarding puis par le test de précision.
    public var level: Int
    public var hasCompletedOnboarding: Bool
    public var migratedFromV3: Bool
    /// Mots aimés de Words v3 sans fiche correspondante, importés quand le pack anglais historique arrive (M8).
    public var pendingV3Headwords: [String]
    /// Valeur de `com.words.premiumAccess` relevée avant la suppression des clés v3 (règle 5 de `04_MIGRATION.md`).
    public var legacyPremiumFlag: Bool
    public var createdAt: Date

    public init(createdAt: Date = .now) {
        self.firstName = nil
        self.ageRange = nil
        self.attribution = nil
        self.goals = []
        self.level = Rules.defaultLevel.rawValue
        self.hasCompletedOnboarding = false
        self.migratedFromV3 = false
        self.pendingV3Headwords = []
        self.legacyPremiumFlag = false
        self.createdAt = createdAt
    }
}

@Model public final class Preferences {
    public var dailyGoal: Int
    public var followedFamilies: [String]
    public var followedThemes: [String]
    public var showFamiliar: Bool
    public var mutedTerms: [String]
    public var voiceIdentifier: String?
    public var appearance: Appearance
    public var soundMode: SoundMode
    public var hapticsEnabled: Bool
    public var animationsEnabled: Bool
    public var autoAdvance: Bool
    public var eveningStreakReminder: Bool

    public init() {
        self.dailyGoal = Rules.defaultDailyGoal
        self.followedFamilies = []
        self.followedThemes = []
        self.showFamiliar = true
        self.mutedTerms = []
        self.voiceIdentifier = nil
        self.appearance = .automatic
        self.soundMode = .effects
        self.hapticsEnabled = true
        self.animationsEnabled = true
        self.autoAdvance = true
        self.eveningStreakReminder = true
    }
}

/// Une ligne par fiche rencontrée.
@Model public final class FicheState {
    @Attribute(.unique) public var ficheID: String
    public var firstSeenAt: Date
    public var lastSeenAt: Date
    public var sorting: Sorting?
    public var sortedAt: Date?
    /// 0 = hors révision, 1…4 = boîtes de Leitner.
    public var box: Int
    public var nextReviewAt: Date?
    public var masteredAt: Date?
    public var correctCount: Int
    public var wrongCount: Int

    public init(ficheID: String, seenAt: Date) {
        self.ficheID = ficheID
        self.firstSeenAt = seenAt
        self.lastSeenAt = seenAt
        self.sorting = nil
        self.sortedAt = nil
        self.box = 0
        self.nextReviewAt = nil
        self.masteredAt = nil
        self.correctCount = 0
        self.wrongCount = 0
    }

    public var review: ReviewState {
        get { ReviewState(box: box, nextReviewAt: nextReviewAt, masteredAt: masteredAt) }
        set { box = newValue.box; nextReviewAt = newValue.nextReviewAt; masteredAt = newValue.masteredAt }
    }

    public var progress: FicheProgress {
        FicheProgress(ficheID: ficheID, firstSeenAt: firstSeenAt, lastSeenAt: lastSeenAt, sorting: sorting, sortedAt: sortedAt, review: review)
    }
}

/// Collection de fiches de l'utilisateur (`Collection` dans la spec, renommé pour ne pas masquer `Swift.Collection`).
@Model public final class UserCollection {
    public var name: String
    public var ficheIDs: [String]
    public var isFollowed: Bool
    public var createdAt: Date

    public init(name: String, ficheIDs: [String] = [], isFollowed: Bool = false, createdAt: Date = .now) {
        self.name = name; self.ficheIDs = ficheIDs; self.isFollowed = isFollowed; self.createdAt = createdAt
    }
}

@Model public final class OwnWord {
    public var headword: String
    public var definition: String
    public var partOfSpeech: PartOfSpeech
    public var gender: Gender?
    public var createdAt: Date

    public init(headword: String, definition: String, partOfSpeech: PartOfSpeech, gender: Gender? = nil, createdAt: Date = .now) {
        self.headword = headword; self.definition = definition; self.partOfSpeech = partOfSpeech
        self.gender = gender; self.createdAt = createdAt
    }
}

@Model public final class PracticeSession {
    public var mode: PracticeMode
    public var startedAt: Date
    public var endedAt: Date?
    public var score: Int
    public var total: Int
    @Relationship(deleteRule: .cascade) public var answers: [PracticeAnswer]

    public init(mode: PracticeMode, startedAt: Date = .now) {
        self.mode = mode; self.startedAt = startedAt; self.endedAt = nil
        self.score = 0; self.total = 0; self.answers = []
    }
}

@Model public final class PracticeAnswer {
    public var ficheID: String
    public var game: GameType
    public var skill: Skill
    public var isCorrect: Bool
    public var responseMs: Int
    public var answeredAt: Date

    public init(ficheID: String, game: GameType, skill: Skill, isCorrect: Bool, responseMs: Int, answeredAt: Date = .now) {
        self.ficheID = ficheID; self.game = game; self.skill = skill
        self.isCorrect = isCorrect; self.responseMs = responseMs; self.answeredAt = answeredAt
    }
}

@Model public final class LevelTestResult {
    public var score: Int
    public var outOf: Int
    public var level: Int
    public var takenAt: Date

    public init(score: Int, outOf: Int, level: Int, takenAt: Date = .now) {
        self.score = score; self.outOf = outOf; self.level = level; self.takenAt = takenAt
    }
}

/// Activité d'une journée Sagace (`day` = identifiant de `SagaceDay`).
@Model public final class ActivityDay {
    @Attribute(.unique) public var day: Date
    public var sorted: Int
    public var reviewsDone: Int
    public var sessions: Int
    public var goalReached: Bool

    public init(day: Date) {
        self.day = day; self.sorted = 0; self.reviewsDone = 0; self.sessions = 0; self.goalReached = false
    }

    public var activity: DayActivity {
        DayActivity(day: day, sorted: sorted, reviewsDone: reviewsDone, sessions: sessions, goalReached: goalReached)
    }
}

@Model public final class Reminder {
    public var source: ReminderSource
    public var sourceID: String?
    public var count: Int
    public var startMinute: Int
    public var endMinute: Int
    public var weekdays: [Int]
    public var soundID: String
    public var isEnabled: Bool

    public init(source: ReminderSource = .fichesDuJour, sourceID: String? = nil, count: Int = 1,
                startMinute: Int = Rules.defaultReminderStartMinute, endMinute: Int = Rules.defaultReminderEndMinute,
                weekdays: [Int] = Array(1...7), soundID: String = "default", isEnabled: Bool = true) {
        self.source = source; self.sourceID = sourceID; self.count = count; self.startMinute = startMinute
        self.endMinute = endMinute; self.weekdays = weekdays; self.soundID = soundID; self.isEnabled = isEnabled
    }
}

@Model public final class WidgetConfig {
    public var kind: WidgetKind
    public var families: [String]
    public var refresh: RefreshRate
    public var showQuote: Bool

    public init(kind: WidgetKind, families: [String] = [], refresh: RefreshRate = .daily, showQuote: Bool = false) {
        self.kind = kind; self.families = families; self.refresh = refresh; self.showQuote = showQuote
    }
}

@Model public final class ErrorReport {
    public var ficheID: String
    public var reason: String
    public var comment: String?
    public var createdAt: Date
    public var sent: Bool

    public init(ficheID: String, reason: String, comment: String? = nil, createdAt: Date = .now) {
        self.ficheID = ficheID; self.reason = reason; self.comment = comment; self.createdAt = createdAt; self.sent = false
    }
}

@Model public final class Achievement {
    @Attribute(.unique) public var id: String
    public var unlockedAt: Date

    public init(id: String, unlockedAt: Date = .now) {
        self.id = id; self.unlockedAt = unlockedAt
    }
}
