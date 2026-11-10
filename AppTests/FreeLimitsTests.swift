import Foundation
import SagaceCore
import Testing
@testable import VocabularyAppFramework

/// Un gratuit atteint ses limites (2 × objectif, 1 session de jeu par jour) et voit le verrou ; un premium non.
@MainActor
@Suite("Limites gratuites")
struct FreeLimitsTests {

    private func feed(_ world: TestWorld, premium: Bool) -> FeedViewModel {
        FeedViewModel(
            content: world.content, topics: world.topics, store: world.progress, library: world.library,
            practice: world.practice, audio: SilentAudio(), entitlements: FakePremium(premium), haptics: SilentHaptics(),
            analytics: RecordingAnalytics(), day: SagaceDay(), defaults: UserDefaults(suiteName: UUID().uuidString)!
        )
    }

    private func fichePages(_ viewModel: FeedViewModel) -> [String] {
        viewModel.pages.compactMap { if case .fiche(let id) = $0.item { id } else { nil } }
    }

    @Test("Feed gratuit : 2 × objectif fiches nouvelles par jour, puis la carte de fin")
    func feedLimit() throws {
        let world = try TestWorld()
        world.progress.preferences.dailyGoal = 5
        let viewModel = feed(world, premium: false)
        viewModel.load()
        let first = fichePages(viewModel)
        #expect(first.count == 10)
        for id in first { _ = world.progress.sort(id, as: .known, at: .now) }

        viewModel.load()
        #expect(fichePages(viewModel).isEmpty)
        #expect(viewModel.pages.map(\.item) == [.end])
        #expect(viewModel.hoursToNextBatch != nil, "La frise annonce le prochain lot")
        #expect(!viewModel.isPremium, "La carte de fin propose « Débloquer plus de fiches »")
    }

    @Test("Feed premium : un nouveau lot même après 10 fiches")
    func feedPremium() throws {
        let world = try TestWorld()
        world.progress.preferences.dailyGoal = 5
        let free = feed(world, premium: false)
        free.load()
        for id in fichePages(free) { _ = world.progress.sort(id, as: .known, at: .now) }

        let premium = feed(world, premium: true)
        premium.load()
        #expect(!fichePages(premium).isEmpty)
        #expect(premium.hoursToNextBatch == nil)
    }

    private func session(_ world: TestWorld, _ kind: PracticeSessionViewModel.Kind, premium: Bool) -> PracticeSessionViewModel {
        PracticeSessionViewModel(
            kind: kind, content: world.content, recorder: world.practice, progress: world.progress,
            entitlements: FakePremium(premium), haptics: SilentHaptics(), analytics: RecordingAnalytics(), now: { .now }
        )
    }

    private func play(_ viewModel: PracticeSessionViewModel) async {
        await viewModel.start()
        while let question = viewModel.current, viewModel.phase == .question {
            viewModel.select(question.correct)
            viewModel.next()
        }
    }

    @Test("Practice gratuit : une session de jeu par jour, défis compris ; ensuite le bandeau PRO")
    func practiceLimit() async throws {
        let world = try TestWorld()
        let first = session(world, .session(.game(.sens)), premium: false)
        await play(first)
        #expect(first.phase == .finished)

        let second = session(world, .session(.game(.motJuste)), premium: false)
        await second.start()
        #expect(second.phase == .locked)

        let challenge = ChallengeViewModel(kind: .rush, content: world.content, recorder: world.practice, entitlements: FakePremium(false),
                                           haptics: SilentHaptics(), analytics: RecordingAnalytics(), now: { .now })
        await challenge.begin()
        #expect(challenge.phase == .locked)
    }

    @Test("Test de précision et révisions restent libres ; le premium n'a pas de limite")
    func notLimited() async throws {
        let world = try TestWorld()
        await play(session(world, .session(.game(.sens)), premium: false))

        let test = session(world, .levelTest, premium: false)
        await test.start()
        #expect(test.phase == .question)

        let review = session(world, .session(.review(["fr.eminent", "fr.pallier"])), premium: false)
        await review.start()
        #expect(review.phase == .question)

        let premium = session(world, .session(.game(.motJuste)), premium: true)
        await premium.start()
        #expect(premium.phase == .question)
    }
}
