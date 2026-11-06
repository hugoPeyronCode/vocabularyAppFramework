import SagaceCore
import SagaceData

extension FeedProfile {
    /// Profil de sélection du feed, lu dans le profil, les préférences et les collections suivies.
    @MainActor
    init(store: any ProgressStoring, library: any LibraryStoring) {
        let profile = store.profile
        let preferences = store.preferences
        self.init(
            level: Level(rawValue: profile.level) ?? Rules.defaultLevel,
            goals: Set(profile.goals),
            followedFamilies: Set(preferences.followedFamilies.compactMap(Family.init(rawValue:))),
            followedThemes: Set(preferences.followedThemes),
            showFamiliar: preferences.showFamiliar,
            mutedTerms: Set(preferences.mutedTerms),
            followedFicheIDs: library.followedFicheIDs()
        )
    }
}
