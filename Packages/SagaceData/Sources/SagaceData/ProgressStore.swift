import Foundation
import SagaceCore
import SwiftData

/// Résultat d'un tri dans le feed.
public struct SortResult: Equatable, Sendable {
    public let sortedToday: Int
    /// L'objectif du jour vient d'être atteint par ce tri.
    public let goalJustReached: Bool
}

/// Résultat d'une révision dans le feed.
public struct ReviewResult: Equatable, Sendable {
    public let outcome: ReviewOutcome
    public let previousBox: Int
    /// Jours entre le tri "À retenir" et la maîtrise, quand le mot vient d'être maîtrisé.
    public let daysToMaster: Int?
    public let masteredCount: Int
}

/// Lecture et écriture de la progression. Les règles viennent de `SagaceCore`, ce type ne fait qu'appliquer et persister.
@MainActor
public protocol ProgressStoring: AnyObject {
    var profile: UserProfile { get }
    var preferences: Preferences { get }
    func allProgress() -> [String: FicheProgress]
    /// Marque la fiche comme vue. Renvoie `true` si c'est la première fois.
    @discardableResult func markSeen(_ ficheID: String, at now: Date) -> Bool
    func sort(_ ficheID: String, as sorting: Sorting, at now: Date) -> SortResult
    func answerReview(_ ficheID: String, correct: Bool, at now: Date) -> ReviewResult
    func activity() -> [DayActivity]
    /// Fiches triées pendant la journée `day` (identifiant `SagaceDay`), dans l'ordre du tri.
    func sortedFiches(on day: Date) -> [(ficheID: String, sorting: Sorting)]
    func masteredCount() -> Int
    func save()
}

@MainActor
public final class ProgressStore: ProgressStoring {
    private let context: ModelContext
    private let day: SagaceDay
    private let scheduler: ReviewScheduler

    public init(context: ModelContext, day: SagaceDay = SagaceDay()) {
        self.context = context
        self.day = day
        self.scheduler = ReviewScheduler(day: day)
    }

    // MARK: Singletons

    public var profile: UserProfile {
        if let existing = try? context.fetch(FetchDescriptor<UserProfile>()).first { return existing }
        let profile = UserProfile()
        context.insert(profile)
        return profile
    }

    public var preferences: Preferences {
        if let existing = try? context.fetch(FetchDescriptor<Preferences>()).first { return existing }
        let preferences = Preferences()
        context.insert(preferences)
        return preferences
    }

    // MARK: Fiches

    public func allProgress() -> [String: FicheProgress] {
        let states = (try? context.fetch(FetchDescriptor<FicheState>())) ?? []
        return Dictionary(states.map { ($0.ficheID, $0.progress) }, uniquingKeysWith: { first, _ in first })
    }

    public func state(for ficheID: String) -> FicheState? {
        var descriptor = FetchDescriptor<FicheState>(predicate: #Predicate { $0.ficheID == ficheID })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    @discardableResult
    public func markSeen(_ ficheID: String, at now: Date) -> Bool {
        if let state = state(for: ficheID) {
            state.lastSeenAt = now
            return false
        }
        context.insert(FicheState(ficheID: ficheID, seenAt: now))
        return true
    }

    public func sort(_ ficheID: String, as sorting: Sorting, at now: Date) -> SortResult {
        let state = state(for: ficheID) ?? {
            let state = FicheState(ficheID: ficheID, seenAt: now)
            context.insert(state)
            return state
        }()
        let isFirstSort = state.sorting == nil
        if state.sorting != sorting {
            state.sorting = sorting
            state.review = sorting == .toLearn ? scheduler.startLearning(at: now) : ReviewState()
        }
        state.sortedAt = state.sortedAt ?? now
        state.lastSeenAt = now

        let activity = activityDay(for: now)
        let wasReached = activity.goalReached
        if isFirstSort { activity.sorted += 1 }
        activity.goalReached = FeedEngine.isGoalReached(sortedToday: activity.sorted, dailyGoal: preferences.dailyGoal)
        save()
        return SortResult(sortedToday: activity.sorted, goalJustReached: activity.goalReached && !wasReached)
    }

    /// Import sans compter d'activité (migration v3) : la fiche entre en révision comme un "À retenir".
    public func importToLearn(_ ficheID: String, at now: Date) {
        let state = state(for: ficheID) ?? {
            let state = FicheState(ficheID: ficheID, seenAt: now)
            context.insert(state)
            return state
        }()
        guard state.sorting == nil else { return }
        state.sorting = .toLearn
        state.sortedAt = now
        state.review = scheduler.startLearning(at: now)
    }

    public func answerReview(_ ficheID: String, correct: Bool, at now: Date) -> ReviewResult {
        guard let state = state(for: ficheID) else {
            return ReviewResult(outcome: .reset(nextInDays: 1), previousBox: 0, daysToMaster: nil, masteredCount: masteredCount())
        }
        let previousBox = state.box
        let (review, outcome) = scheduler.answer(state.review, correct: correct, at: now)
        state.review = review
        if correct { state.correctCount += 1 } else { state.wrongCount += 1 }
        activityDay(for: now).reviewsDone += 1
        save()
        let daysToMaster = outcome == .mastered ? state.sortedAt.map { day.days(from: $0, to: now) } : nil
        return ReviewResult(outcome: outcome, previousBox: previousBox, daysToMaster: daysToMaster, masteredCount: masteredCount())
    }

    public func masteredCount() -> Int {
        (try? context.fetchCount(FetchDescriptor<FicheState>(predicate: #Predicate { $0.masteredAt != nil }))) ?? 0
    }

    public func sortedFiches(on day: Date) -> [(ficheID: String, sorting: Sorting)] {
        let start = self.day.start(of: day)
        let end = self.day.start(of: self.day.adding(days: 1, to: day))
        let descriptor = FetchDescriptor<FicheState>(
            predicate: #Predicate { state in
                if let sortedAt = state.sortedAt {
                    sortedAt >= start && sortedAt < end
                } else {
                    false
                }
            },
            sortBy: [SortDescriptor(\.sortedAt)]
        )
        let states = (try? context.fetch(descriptor)) ?? []
        return states.compactMap { state in state.sorting.map { (state.ficheID, $0) } }
    }

    // MARK: Activité

    public func activity() -> [DayActivity] {
        let days = (try? context.fetch(FetchDescriptor<ActivityDay>(sortBy: [SortDescriptor(\.day)]))) ?? []
        return days.map(\.activity)
    }

    private func activityDay(for date: Date) -> ActivityDay {
        let key = day.day(of: date)
        var descriptor = FetchDescriptor<ActivityDay>(predicate: #Predicate { $0.day == key })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first { return existing }
        let activity = ActivityDay(day: key)
        context.insert(activity)
        return activity
    }

    public func save() {
        try? context.save()
    }
}
