import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftUI

/// Feed (FEED-01 à 04) : pages de fiches et de révisions, tri, objectif du jour, frise et série.
@MainActor @Observable
final class FeedViewModel {
    struct Page: Identifiable, Hashable {
        let id: String
        let item: FeedItem

        var ficheID: String? {
            switch item {
            case .fiche(let id), .review(let id): id
            case .end: nil
            }
        }
    }

    struct DayCell: Identifiable, Hashable {
        let day: Date
        let progress: Double
        let isToday: Bool
        let isFuture: Bool
        var id: Date { day }
    }

    struct ReviewCard: Equatable {
        let ficheID: String
        let quiz: QuizItem
        let daysSinceSorted: Int?
        var selected: Int?
        var outcome: ReviewOutcome?
    }

    struct GoalToast: Equatable {
        let goal: Int
        let streak: Int
    }

    struct Mastered: Identifiable, Equatable {
        let headword: String
        let count: Int
        var id: String { headword }
    }

    private(set) var pages: [Page] = []
    var currentPageID: String?
    private(set) var sortings: [String: Sorting] = [:]
    private(set) var reviews: [String: ReviewCard] = [:]
    private(set) var week: [DayCell] = []
    private(set) var streak = 0
    private(set) var dailyGoal = Rules.defaultDailyGoal
    private(set) var goalToast: GoalToast?
    var mastered: Mastered?
    var isShowingGameSuggestion = false

    private let content: ContentRepository
    private let topics: Topics
    private let store: any ProgressStoring
    private let library: any LibraryStoring
    private let practice: any PracticeRecording
    private let audio: any Speaking
    private let entitlements: any PremiumProviding
    private let haptics: any HapticPlaying
    private let analytics: any Analytics
    private let day: SagaceDay
    private let defaults: UserDefaults
    private let now: () -> Date
    private let engine: FeedEngine
    private let streaks: StreakCalculator
    private var viewedThisSession: Set<String> = []
    private var loadedDay: Date?

    private static let gameSuggestionDayKey = "feed.gameSuggestionDay"

    init(
        content: ContentRepository, topics: Topics, store: any ProgressStoring, library: any LibraryStoring,
        practice: any PracticeRecording, audio: any Speaking, entitlements: any PremiumProviding, haptics: any HapticPlaying, analytics: any Analytics,
        day: SagaceDay, defaults: UserDefaults = .standard, now: @escaping () -> Date = { .now }
    ) {
        self.content = content; self.topics = topics; self.store = store; self.library = library
        self.practice = practice; self.audio = audio
        self.entitlements = entitlements
        self.haptics = haptics; self.analytics = analytics; self.day = day; self.defaults = defaults; self.now = now
        self.engine = FeedEngine(day: day)
        self.streaks = StreakCalculator(day: day)
    }

    var isPremium: Bool { entitlements.isPremium }

    var currentPage: Page? { pages.first { $0.id == currentPageID } }

    /// Fiche triable de la page courante (pas une révision ni la carte de fin).
    var currentSortableFicheID: String? {
        guard let page = currentPage, case .fiche(let id) = page.item else { return nil }
        return id
    }

    /// Lot gratuit épuisé : la frise affiche le délai avant le prochain lot.
    var hoursToNextBatch: Int? {
        let fichePages = pages.filter { if case .fiche = $0.item { true } else { false } }
        let isFinished = currentPage?.item == .end || (!fichePages.isEmpty && fichePages.allSatisfy { sortings[$0.ficheID ?? ""] != nil })
        guard isFinished, !isPremium else { return nil }
        let seconds = day.nextBatch(after: now()).timeIntervalSince(now())
        return max(1, Int((seconds / 3600).rounded(.up)))
    }

    func fiche(_ id: String) -> Fiche? { content.fiche(id: id) }

    func familyName(of fiche: Fiche) -> String {
        topics.families.first { $0.id == fiche.family }?.name ?? ""
    }

    // MARK: Chargement

    func load() {
        let now = now()
        let progress = store.allProgress()
        let preferences = store.preferences
        dailyGoal = preferences.dailyGoal
        let today = day.day(of: now)
        loadedDay = today

        let seenToday = progress.values
            .filter { $0.firstSeenAt.map { day.day(of: $0) == today } ?? false }
            .sorted { ($0.firstSeenAt ?? now) < ($1.firstSeenAt ?? now) }
        let carriedOver = seenToday.filter { $0.sorting == nil && content.fiche(id: $0.ficheID) != nil }.map(\.ficheID)
        let allowance = engine.newFicheAllowance(dailyGoal: dailyGoal, isPremium: isPremium, newSeenToday: seenToday.count)
        let picked = engine.pickNew(
            allowance,
            from: engine.eligible(content.fiches, progress: progress, profile: feedProfile, at: now),
            profile: feedProfile,
            seed: engine.seed(for: now)
        ).map(\.id)
        let due = engine.dueReviews(progress.values, at: now).filter { content.fiche(id: $0) != nil }

        reviews = Dictionary(uniqueKeysWithValues: due.compactMap { id in reviewCard(for: id, progress: progress[id], now: now).map { (id, $0) } })
        pages = FeedEngine.interleave(fiches: carriedOver + picked, reviews: due.filter { reviews[$0] != nil })
            .map { Page(id: Self.pageID(for: $0), item: $0) } + [Page(id: "end", item: .end)]
        sortings = [:]
        currentPageID = pages.first?.id
        refreshProgress()
    }

    private var feedProfile: FeedProfile {
        let profile = store.profile
        let preferences = store.preferences
        return FeedProfile(
            level: Level(rawValue: profile.level) ?? Rules.defaultLevel,
            goals: Set(profile.goals),
            followedFamilies: Set(preferences.followedFamilies.compactMap(Family.init(rawValue:))),
            followedThemes: Set(preferences.followedThemes),
            showFamiliar: preferences.showFamiliar,
            mutedTerms: Set(preferences.mutedTerms),
            followedFicheIDs: library.followedFicheIDs()
        )
    }

    private func reviewCard(for ficheID: String, progress: FicheProgress?, now: Date) -> ReviewCard? {
        guard let fiche = content.fiche(id: ficheID), !fiche.quiz.isEmpty else { return nil }
        let box = max(progress?.review.box ?? 1, 1)
        return ReviewCard(
            ficheID: ficheID,
            quiz: fiche.quiz[(box - 1) % fiche.quiz.count],
            daysSinceSorted: progress?.sortedAt.map { day.days(from: $0, to: now) }
        )
    }

    private static func pageID(for item: FeedItem) -> String {
        switch item {
        case .fiche(let id): "fiche:\(id)"
        case .review(let id): "review:\(id)"
        case .end: "end"
        }
    }

    // MARK: Navigation

    /// Appelé quand une page devient visible.
    func pageDidAppear(_ pageID: String?) {
        guard let page = pages.first(where: { $0.id == pageID }) else { return }
        if case .fiche(let id) = page.item, let fiche = content.fiche(id: id), viewedThisSession.insert(page.id).inserted {
            store.markSeen(id, at: now())
            store.save()
            analytics.track(.ficheViewed(ficheID: id, family: fiche.family, origin: .feed))
        }
        if page.item == .end, isPremium { appendNextBatch() }
    }

    func pageDidChange() {
        haptics.play(.selection)
    }

    private func advance(from pageID: String) {
        guard currentPageID == pageID, let index = pages.firstIndex(where: { $0.id == pageID }), pages.indices.contains(index + 1) else { return }
        withAnimation(SagaceMotion.page) { currentPageID = pages[index + 1].id }
    }

    /// Premium : un nouveau lot quand la carte de fin apparaît, s'il reste des fiches.
    private func appendNextBatch() {
        let now = now()
        let alreadyInFeed = Set(pages.compactMap(\.ficheID))
        let more = engine.pickNew(
            engine.newFicheAllowance(dailyGoal: dailyGoal, isPremium: true, newSeenToday: 0),
            from: engine.eligible(content.fiches, progress: store.allProgress(), profile: feedProfile, at: now)
                .filter { !alreadyInFeed.contains($0.id) },
            profile: feedProfile,
            seed: engine.seed(for: now) &+ UInt64(pages.count)
        )
        guard !more.isEmpty else { return }
        let newPages = more.map { Page(id: Self.pageID(for: .fiche($0.id)), item: .fiche($0.id)) }
        pages.insert(contentsOf: newPages, at: pages.count - 1)
    }

    /// FEED-06 "Revoir ces fiches" : les fiches du jour reviennent juste après la page courante.
    func replay(_ ficheIDs: [String]) {
        let progress = store.allProgress()
        let replayPages = ficheIDs.filter { content.fiche(id: $0) != nil }.map { Page(id: "replay:\($0):\(UUID().uuidString)", item: .fiche($0)) }
        guard let first = replayPages.first else { return }
        for id in ficheIDs { sortings[id] = progress[id]?.sorting }
        let index = pages.firstIndex { $0.id == currentPageID }.map { $0 + 1 } ?? 0
        pages.insert(contentsOf: replayPages, at: index)
        withAnimation(SagaceMotion.page) { currentPageID = first.id }
    }

    /// FEED-04 : trois jeux, ceux de la compétence la plus faible d'abord.
    var suggestedGames: [GameType] {
        let stats = PracticeStats(day: day)
        let accuracy = stats.accuracy(practice.answers(), at: now())
        let bySkill = Skill.allCases.sorted { (accuracy[$0]?.percent ?? 100) < (accuracy[$1]?.percent ?? 100) }
        let weakestFirst = stats.suggestedSkill(accuracy) == nil ? [GameType.motJuste, .paronymes, .justeOuFautif] : bySkill.flatMap(\.games)
        return Array(weakestFirst.prefix(3))
    }

    func speak(_ ficheID: String) {
        guard let fiche = content.fiche(id: ficheID) else { return }
        audio.speak(fiche.headword)
    }

    /// Après une sheet (fiche détaillée, Explorer) : tris faits ailleurs, frise et série à jour.
    func refreshAfterSheet() {
        let progress = store.allProgress()
        for id in pages.compactMap(\.ficheID) where progress[id]?.sorting != nil {
            sortings[id] = progress[id]?.sorting
        }
        refreshProgress()
    }

    // MARK: Tri

    func sort(_ sorting: Sorting) {
        guard let page = currentPage, case .fiche(let ficheID) = page.item else { return }
        let result = store.sort(ficheID, as: sorting, at: now())
        sortings[ficheID] = sorting
        analytics.track(.ficheSorted(ficheID: ficheID, sorting: sorting))
        refreshProgress()
        if result.goalJustReached {
            haptics.play(.success)
            reachGoal()
        } else {
            haptics.play(.light)
        }
        Task {
            try? await Task.sleep(for: .seconds(Rules.sortAutoAdvanceDelay))
            advance(from: page.id)
        }
    }

    private func reachGoal() {
        analytics.track(.dailyGoalCompleted(streak: streak))
        let toast = GoalToast(goal: dailyGoal, streak: streak)
        goalToast = toast
        let today = day.day(of: now()).timeIntervalSinceReferenceDate
        let showSuggestion = defaults.double(forKey: Self.gameSuggestionDayKey) != today
        if showSuggestion { defaults.set(today, forKey: Self.gameSuggestionDayKey) }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            if goalToast == toast { goalToast = nil }
            if showSuggestion { isShowingGameSuggestion = true }
        }
    }

    // MARK: Révision (FEED-02, FEED-03)

    func answerReview(_ ficheID: String, choice: Int) {
        guard var card = reviews[ficheID], card.selected == nil else { return }
        let correct = choice == card.quiz.answerIndex
        let result = store.answerReview(ficheID, correct: correct, at: now())
        card.selected = choice
        card.outcome = result.outcome
        reviews[ficheID] = card
        analytics.track(.reviewAnswered(ficheID: ficheID, box: result.previousBox, correct: correct))
        refreshProgress()
        switch result.outcome {
        case .mastered:
            haptics.play(.celebration)
            analytics.track(.ficheMastered(ficheID: ficheID, daysToMaster: result.daysToMaster ?? 0))
            if let fiche = content.fiche(id: ficheID) {
                mastered = Mastered(headword: fiche.headword, count: result.masteredCount)
            }
        case .promoted:
            haptics.play(.success)
        case .reset:
            haptics.play(.error)
        }
    }

    func answerState(for ficheID: String, choice: Int) -> AnswerRow.State {
        guard let card = reviews[ficheID], let selected = card.selected else { return .idle }
        if choice == card.quiz.answerIndex { return .correct }
        return choice == selected ? .wrong : .dimmed
    }

    // MARK: Frise et série

    private func refreshProgress() {
        let now = now()
        let activity = store.activity()
        let byDay = Dictionary(activity.map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first })
        let today = day.day(of: now)
        week = day.week(containing: now).map { date in
            let sorted = byDay[date]?.sorted ?? 0
            return DayCell(day: date, progress: Double(sorted) / Double(max(dailyGoal, 1)), isToday: date == today, isFuture: date > today)
        }
        streak = streaks.summary(of: activity, at: now).current
    }

    /// Retour au premier plan : nouveau lot si la journée Sagace a changé (4 h), sinon frise et série à jour.
    func sceneDidBecomeActive() {
        if loadedDay != day.day(of: now()) { load() } else { refreshProgress() }
    }
}
