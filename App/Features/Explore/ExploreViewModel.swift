import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI

/// Explorer (EXP-01) et recherche (EXP-03).
@MainActor @Observable
final class ExploreViewModel {
    struct Counts: Equatable {
        var toLearn = 0
        var mastered = 0
        var collections = 0
        var ownWords = 0
        var reports = 0
    }

    let families: [Topics.FamilyInfo]
    let themes: [Topics.ThemeInfo]
    private(set) var counts = Counts()
    private(set) var followedFamilies: Set<Family> = []
    private(set) var followedThemes: Set<String> = []
    private(set) var results: [Fiche] = []
    private(set) var suggestionSent = false
    var query = "" {
        didSet {
            results = content.searchIndex.search(query)
            suggestionSent = false
        }
    }

    private let content: ContentRepository
    private let store: any ProgressStoring
    private let library: any LibraryStoring
    private let entitlements: any PremiumProviding
    private let haptics: any HapticPlaying
    private let now: () -> Date

    init(
        content: ContentRepository, topics: Topics, store: any ProgressStoring, library: any LibraryStoring,
        entitlements: any PremiumProviding, haptics: any HapticPlaying, now: @escaping () -> Date
    ) {
        self.content = content; self.store = store; self.library = library
        self.entitlements = entitlements; self.haptics = haptics; self.now = now
        self.families = topics.families
        self.themes = topics.themes
    }

    var isPremium: Bool { entitlements.isPremium }
    var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    func load() {
        let progress = store.allProgress().values.filter { content.fiche(id: $0.ficheID) != nil }
        let library = Library()
        counts = Counts(
            toLearn: library.toLearn(progress, at: now()).count,
            mastered: library.mastered(progress).count,
            collections: self.library.collections().count,
            ownWords: self.library.ownWords().count,
            reports: self.library.reports().count
        )
        let preferences = store.preferences
        followedFamilies = Set(preferences.followedFamilies.compactMap(Family.init(rawValue:)))
        followedThemes = Set(preferences.followedThemes)
    }

    func ficheCount(for family: Family) -> Int { content.fiches(in: family).count }
    func ficheCount(forTheme theme: String) -> Int { content.fiches(theme: theme).count }

    /// "Proposer ce mot ?" : la suggestion part dans la file locale des signalements.
    func suggestQuery() {
        let word = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty, !suggestionSent else { return }
        library.report(ficheID: "", reason: .suggestion, comment: word)
        haptics.play(.success)
        suggestionSent = true
    }
}
