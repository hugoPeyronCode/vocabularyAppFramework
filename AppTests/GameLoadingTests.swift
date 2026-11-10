import Foundation
import SagaceCore
import SagaceData
import SwiftData
import Testing
@testable import VocabularyAppFramework

private actor SuspendedQuestions: QuestionPreparing {
    private var response: CheckedContinuation<[Question], Never>?
    private var waiter: CheckedContinuation<Void, Never>?
    private var started = false

    func session(_ kind: PracticeSessionViewModel.Kind, seed: UInt64) async -> [Question] { await suspend() }
    func challenge(_ kind: ChallengeState.Kind, seed: UInt64, excluding: Set<String>) async -> [Question] { await suspend() }

    private func suspend() async -> [Question] {
        await withCheckedContinuation { continuation in
            response = continuation
            started = true
            waiter?.resume()
            waiter = nil
        }
    }

    func waitUntilStarted() async {
        if !started { await withCheckedContinuation { waiter = $0 } }
    }

    func finish(with questions: [Question]) { response?.resume(returning: questions); response = nil }
}

@MainActor
@Suite("Chargement et présentation des jeux")
struct GameLoadingTests {
    private let question = Question(id: "test", ficheID: "fr.eminent", game: .motJuste, prompt: "Un ___ chercheur.",
                                    choices: ["éminent", "imminent", "immédiat"], correct: .choice(0), explanation: "Remarquable.")

    @Test("Le chargement laisse l'interface disponible et ne compte pas une partie annulée")
    func cancelledSession() async throws {
        let world = try TestWorld()
        let preparation = SuspendedQuestions()
        let model = PracticeSessionViewModel(kind: .session(.game(.motJuste)), content: world.content, preparation: preparation,
                                            recorder: world.practice, progress: world.progress, entitlements: FakePremium(true),
                                            haptics: SilentHaptics(), analytics: RecordingAnalytics(), now: { .now })
        let task = Task { await model.start() }
        await preparation.waitUntilStarted()
        #expect(model.phase == .loading)
        #expect(try world.container.mainContext.fetchCount(FetchDescriptor<PracticeSession>()) == 0)
        model.cancelPreparation()
        task.cancel()
        await preparation.finish(with: [question])
        await task.value
        #expect(model.current == nil)
        #expect(try world.container.mainContext.fetchCount(FetchDescriptor<PracticeSession>()) == 0)
    }

    @Test("Le chrono et la partie commencent seulement quand la question est prête")
    func challengeLoading() async throws {
        let world = try TestWorld()
        let preparation = SuspendedQuestions()
        let model = ChallengeViewModel(kind: .rush, content: world.content, preparation: preparation,
                                       recorder: world.practice, entitlements: FakePremium(true),
                                       haptics: SilentHaptics(), analytics: RecordingAnalytics(), now: { .now })
        let task = Task { await model.begin() }
        await preparation.waitUntilStarted()
        #expect(model.phase == .loading)
        #expect(model.current == nil)
        #expect(model.state.remaining == Rules.rushSecondsPerQuestion)
        #expect(try world.container.mainContext.fetchCount(FetchDescriptor<PracticeSession>()) == 0)
        await preparation.finish(with: [question])
        await task.value
        #expect(model.phase == .playing)
        #expect(model.current == question)
        #expect(try world.container.mainContext.fetchCount(FetchDescriptor<PracticeSession>()) == 1)
        model.quit()
    }

    @Test("Les défis préparent dix questions au plus par lot")
    func boundedChallengeBatch() async throws {
        let world = try TestWorld()
        let preparation = QuestionPreparation(content: world.content)
        let questions = await preparation.challenge(.sprint, seed: 42)
        #expect(!questions.isEmpty)
        #expect(questions.count <= Rules.sessionLength)
        #expect(questions.allSatisfy { $0.isWellFormed })
        let used = Set(questions.map(\.ficheID))
        let next = await preparation.challenge(.sprint, seed: 43, excluding: used)
        #expect(!next.isEmpty)
        #expect(used.isDisjoint(with: next.map(\.ficheID)))
    }

    @Test("Depuis Jeux, le plein écran attend la fermeture de la sheet")
    func fullScreenRouting() {
        let router = AppRouter()
        router.open(.practice)
        router.open(.session(.game(.motJuste)))
        #expect(router.sheet == nil)
        #expect(router.fullScreen == nil)
        router.sheetDidDismiss()
        #expect(router.fullScreen == .game(.session(.game(.motJuste))))
        #expect(router.pendingGame == nil)
        router.fullScreen = nil
        router.open(.crossword)
        #expect(router.fullScreen == .game(.crossword))
    }
}
