import Foundation
import SagaceCore
import SwiftData
import Testing
@testable import SagaceData

@MainActor
@Suite("Sessions de pratique")
struct PracticeStoreTests {
    let container: ModelContainer
    let store: PracticeStore
    let progress: ProgressStore

    init() throws {
        container = try SagaceStore.makeContainer(inMemory: true)
        store = PracticeStore(context: container.mainContext, day: TestEnv.day)
        progress = ProgressStore(context: container.mainContext, day: TestEnv.day)
    }

    private func question(_ game: GameType = .sens) -> Question {
        Question(id: "q", ficheID: "fr.a", game: game, prompt: "?", choices: ["a", "b", "c"], correct: .choice(0), explanation: "")
    }

    @Test("Une session terminée compte ses réponses et l'activité du jour")
    func sessionLifecycle() {
        let session = store.start(.sens, at: TestEnv.date())
        store.record(question(), correct: true, responseMs: 900, in: session, at: TestEnv.date())
        store.record(question(.devine), correct: false, responseMs: 1500, in: session, at: TestEnv.date())
        store.finish(session, score: 1, total: 2, at: TestEnv.date())
        #expect(session.answers.count == 2)
        #expect(store.answers().filter(\.isCorrect).count == 1)
        #expect(progress.activity().first?.sessions == 1)
    }

    @Test("Limite gratuite : sessions de jeu et défis du jour, sans le test ni les révisions")
    func gameSessionsToday() {
        for mode in [PracticeMode.sens, .rush, .levelTest, .review] {
            store.finish(store.start(mode, at: TestEnv.date()), score: 0, total: 0, at: TestEnv.date())
        }
        store.finish(store.start(.motJuste, at: TestEnv.date(days: -1)), score: 0, total: 0, at: TestEnv.date(days: -1))
        _ = store.start(.devine, at: TestEnv.date())
        #expect(store.gameSessionsToday(at: TestEnv.date()) == 2)
    }

    @Test("Cercles des 5 derniers jours")
    func sessionDays() {
        for offset in [0, -2] {
            store.finish(store.start(.sens, at: TestEnv.date(days: offset)), score: 0, total: 0, at: TestEnv.date(days: offset))
        }
        #expect(store.sessionDays(last: 5, at: TestEnv.date()) == [false, false, true, false, true])
    }

    @Test("Record personnel par défi")
    func bestScore() {
        for score in [12, 7] {
            store.finish(store.start(.rush, at: TestEnv.date()), score: score, total: 15, at: TestEnv.date())
        }
        #expect(store.bestScore(for: .rush) == 12)
        #expect(store.bestScore(for: .sprint) == nil)
    }

    @Test("Le test de précision fixe le niveau du profil")
    func levelTest() {
        #expect(store.saveLevelTest(score: 16, outOf: 30, at: TestEnv.date()) == .intermediaire)
        #expect(progress.profile.level == 3)
        #expect(store.saveLevelTest(score: 26, outOf: 30, at: TestEnv.date(days: 1)) == .expert)
        #expect(progress.profile.level == 5)
        #expect(store.lastLevelTest()?.score == 26)
    }
}
