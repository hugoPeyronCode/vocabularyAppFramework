import Foundation
import SagaceCore
import Testing
@testable import VocabularyAppFramework

/// Clavier de l'iPad (`09_IPAD.md`) : ↓ fiche suivante, ↑ précédente, sans sortir du feed.
@MainActor
@Suite("Feed au clavier")
struct FeedKeyboardTests {

    @Test("↓ et ↑ changent de page, et s'arrêtent aux bords")
    func arrows() throws {
        let world = try TestWorld()
        let viewModel = FeedViewModel(
            content: world.content, topics: world.topics, store: world.progress, library: world.library,
            practice: world.practice, audio: SilentAudio(), entitlements: FakePremium(false), haptics: SilentHaptics(),
            analytics: RecordingAnalytics(), day: SagaceDay(), defaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        viewModel.load()
        let ids = viewModel.pages.map(\.id)
        try #require(ids.count >= 2)
        #expect(viewModel.currentPageID == ids[0])

        viewModel.showPage(offset: -1)
        #expect(viewModel.currentPageID == ids[0], "Pas de page avant la première")

        viewModel.showPage(offset: 1)
        #expect(viewModel.currentPageID == ids[1])

        viewModel.showPage(offset: -1)
        #expect(viewModel.currentPageID == ids[0])

        for _ in ids { viewModel.showPage(offset: 1) }
        #expect(viewModel.currentPageID == ids.last, "Pas de page après la dernière")
    }
}
