import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftUI

/// Feed (FEED-01, 04, 06) : on fait défiler des mots. Le premier du jour est le mot du jour ; chaque carte
/// montre l'essentiel et se complète à chaque toucher. Les révisions et les jeux sont dans l'espace Jeux.
@MainActor @Observable
final class FeedViewModel {
    struct Page: Identifiable, Hashable {
        let id: String
        let item: FeedItem

        var ficheID: String? {
            switch item {
            case .fiche(let id): id
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

    /// Ce qu'un toucher sur la carte dévoile, dans l'ordre.
    enum Detail: Hashable {
        case confusion(Confusion)
        case usage(UsageNote)
        case example(String)
        case quote(AuthorQuote)
    }

    struct GoalToast: Equatable {
        let goal: Int
        let streak: Int
    }

    private(set) var pages: [Page] = []
    var currentPageID: String?
    private(set) var sortings: [String: Sorting] = [:]
    /// Nombre de détails dévoilés par page.
    private(set) var revealed: [String: Int] = [:]
    private(set) var wordOfTheDayID: String?
    /// Révisions dues, affichées en badge sur la pilule Jeux.
    private(set) var dueReviewCount = 0
    private(set) var week: [DayCell] = []
    private(set) var streak = 0
    private(set) var dailyGoal = Rules.defaultDailyGoal
    private(set) var goalToast: GoalToast?
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
        wordOfTheDayID = seenToday.first(where: { content.fiche(id: $0.ficheID) != nil })?.ficheID ?? picked.first
        pages = (carriedOver + picked).map { Page(id: Self.pageID(for: .fiche($0)), item: .fiche($0)) } + [Page(id: "end", item: .end)]
        sortings = [:]
        revealed = [:]
        currentPageID = pages.first?.id
        refreshProgress()
    }

    private var feedProfile: FeedProfile {
        FeedProfile(store: store, library: library)
    }

    private static func pageID(for item: FeedItem) -> String {
        switch item {
        case .fiche(let id): "fiche:\(id)"
        case .end: "end"
        }
    }

    // MARK: Navigation

    /// Appelé quand une page devient visible.
    func pageDidAppear(_ pageID: String?) {
        guard !isObscured, let page = pages.first(where: { $0.id == pageID }) else { return }
        if case .fiche(let id) = page.item, let fiche = content.fiche(id: id), viewedThisSession.insert(page.id).inserted {
            store.markSeen(id, at: now())
            store.save()
            analytics.track(.ficheViewed(ficheID: id, family: fiche.family, origin: .feed))
        }
        if page.item == .end, isPremium { appendNextBatch() }
    }

    /// Recouvert par la migration ou l'onboarding : la fiche à l'écran n'est pas vue.
    private(set) var isObscured = false

    func setObscured(_ obscured: Bool) {
        isObscured = obscured
        if !obscured { pageDidAppear(currentPageID) }
    }

    func pageDidChange() {
        haptics.play(.selection)
    }

    /// Clavier de l'iPad : ↓ fiche suivante, ↑ précédente.
    func showPage(offset: Int) {
        guard let index = pages.firstIndex(where: { $0.id == currentPageID }), pages.indices.contains(index + offset) else { return }
        withAnimation(SagaceMotion.page) { currentPageID = pages[index + offset].id }
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
        audio.speak(fiche.headword, language: fiche.language)
    }

    /// Après une sheet (fiche détaillée, Explorer) : tris faits ailleurs, frise et série à jour.
    func refreshAfterSheet() {
        let progress = store.allProgress()
        for id in pages.compactMap(\.ficheID) where progress[id]?.sorting != nil {
            sortings[id] = progress[id]?.sorting
        }
        refreshProgress()
    }

    // MARK: Carte

    /// Détails disponibles d'une fiche : confusion, bon usage, exemple, phrase d'auteur.
    func details(of fiche: Fiche) -> [Detail] {
        var details: [Detail] = fiche.confusions.prefix(1).map(Detail.confusion)
        if let usage = fiche.usage { details.append(.usage(usage)) }
        if let example = fiche.examples.first { details.append(.example(example)) }
        if let quote = fiche.authorQuote { details.append(.quote(quote)) }
        return details
    }

    /// Un toucher sur la carte dévoile le détail suivant.
    func reveal(_ pageID: String) {
        guard let ficheID = pages.first(where: { $0.id == pageID })?.ficheID, let fiche = content.fiche(id: ficheID) else { return }
        let count = revealed[pageID, default: 0]
        guard count < details(of: fiche).count else { return }
        revealed[pageID] = count + 1
        haptics.play(.soft)
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
        dueReviewCount = engine.dueReviews(store.allProgress().values, at: now).filter { content.fiche(id: $0) != nil }.count
    }

    /// Retour au premier plan : nouveau lot si la journée Sagace a changé (4 h), sinon frise et série à jour.
    func sceneDidBecomeActive() {
        if loadedDay != day.day(of: now()) { load() } else { refreshProgress() }
    }
}
