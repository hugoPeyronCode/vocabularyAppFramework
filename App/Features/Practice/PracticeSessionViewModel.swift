import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI

/// Session de jeu (PRA-02, PRA-03), révisions du jour et test de précision (PRA-07, PRA-08). Machine à états.
/// Chaque réponse montre son explication ; on passe à la suite avec "Continuer", jamais automatiquement.
@MainActor @Observable
final class PracticeSessionViewModel {
    enum Kind: Equatable {
        case session(PracticeRequest)
        case levelTest
    }

    enum Phase: Equatable {
        /// Introduction du test de précision.
        case intro
        case question
        case answered(correct: Bool)
        case finished
        /// Limite gratuite atteinte : bandeau PRO.
        case locked
        /// Pas assez de fiches pour ce jeu.
        case empty
    }

    struct Answered: Identifiable, Equatable {
        let question: Question
        let fiche: Fiche?
        let isCorrect: Bool
        var id: String { question.id }
    }

    struct LevelOutcome: Equatable {
        let level: Level
        let pointsToNext: Int?
    }

    let kind: Kind
    private(set) var questions: [Question] = []
    private(set) var index = 0
    private(set) var phase: Phase
    private(set) var selected: Question.Answer?
    private(set) var score = 0
    private(set) var answered: [Answered] = []
    private(set) var savedToLearn: Set<String> = []
    private(set) var sessionDays: [Bool] = []
    private(set) var levelOutcome: LevelOutcome?
    /// Révisions : mot maîtrisé par la dernière réponse.
    private(set) var justMastered: String?
    private var reviewed: Set<String> = []

    private let content: ContentRepository
    private let factory: QuestionFactory
    private let recorder: any PracticeRecording
    private let progress: any ProgressStoring
    private let entitlements: any PremiumProviding
    private let haptics: any HapticPlaying
    private let analytics: any Analytics
    private let now: () -> Date
    private var session: PracticeSession?
    private var shownAt = Date()
    private var seedOffset: UInt64 = 0

    init(
        kind: Kind, content: ContentRepository, recorder: any PracticeRecording, progress: any ProgressStoring,
        entitlements: any PremiumProviding, haptics: any HapticPlaying, analytics: any Analytics, now: @escaping () -> Date
    ) {
        self.kind = kind; self.content = content; self.recorder = recorder; self.progress = progress
        self.entitlements = entitlements; self.haptics = haptics; self.analytics = analytics; self.now = now
        self.factory = QuestionFactory(fiches: content.fiches)
        self.phase = kind == .levelTest ? .intro : .question
    }

    var mode: PracticeMode {
        switch kind {
        case .session(let request): request.mode
        case .levelTest: .levelTest
        }
    }

    var isLevelTest: Bool { kind == .levelTest }

    /// Questions en cours : on ne ferme pas la sheet par glissement.
    var isInProgress: Bool {
        switch phase {
        case .question, .answered: true
        default: false
        }
    }
    var current: Question? { questions.indices.contains(index) ? questions[index] : nil }
    var completedCount: Int { index + (phase == .question || phase == .intro ? 0 : 1) }

    // MARK: Démarrage

    func start() {
        if mode.countsAsGameSession,
           !PracticeStats.canStartGame(isPremium: entitlements.isPremium, gameSessionsToday: recorder.gameSessionsToday(at: now())) {
            phase = .locked
            return
        }
        let seed = UInt64(bitPattern: Int64(now().timeIntervalSinceReferenceDate)) &+ seedOffset
        questions = makeQuestions(seed: seed)
        guard !questions.isEmpty else {
            phase = .empty
            return
        }
        index = 0
        score = 0
        answered = []
        savedToLearn = []
        selected = nil
        levelOutcome = nil
        justMastered = nil
        reviewed = []
        phase = .question
        session = recorder.start(mode, at: now())
        shownAt = now()
        analytics.track(.practiceStarted(mode: mode))
    }

    private func makeQuestions(seed: UInt64) -> [Question] {
        switch kind {
        case .levelTest:
            return factory.levelTest(seed: seed)
        case .session(.game(let game)):
            return factory.questions(for: game, from: content.fiches, count: Rules.sessionLength, seed: seed)
        case .session(.family(let family)):
            let games = [GameType.preferred(for: family)] + GameType.allCases.filter { $0 != .preferred(for: family) }
            return factory.mixed(from: content.fiches(in: family), count: Rules.sessionLength, games: games, seed: seed)
        case .session(.fiches(let ids)):
            return factory.mixed(from: ids.compactMap(content.fiche(id:)), count: Rules.sessionLength, seed: seed)
        case .session(.review(let ids)):
            return factory.review(ids.compactMap(content.fiche(id:)), count: Rules.sessionLength, seed: seed)
        }
    }

    // MARK: Réponses

    func select(_ answer: Question.Answer) {
        guard phase == .question, let question = current, let session else { return }
        selected = answer
        let correct = question.isCorrect(answer)
        if correct { score += 1 }
        haptics.play(correct ? .success : .error)
        recorder.record(question, correct: correct, responseMs: Int(now().timeIntervalSince(shownAt) * 1000), in: session, at: now())
        answered.append(Answered(question: question, fiche: content.fiche(id: question.ficheID), isCorrect: correct))
        if case .session(.review) = kind { applyReview(question.ficheID, correct: correct) }
        phase = .answered(correct: correct)
    }

    /// Révisions : la première réponse sur une fiche fait avancer (ou recule) sa boîte de Leitner.
    private func applyReview(_ ficheID: String, correct: Bool) {
        guard reviewed.insert(ficheID).inserted else { return }
        let result = progress.answerReview(ficheID, correct: correct, at: now())
        analytics.track(.reviewAnswered(ficheID: ficheID, box: result.previousBox, correct: correct))
        if result.outcome == .mastered {
            justMastered = content.fiche(id: ficheID)?.headword
            haptics.play(.celebration)
            analytics.track(.ficheMastered(ficheID: ficheID, daysToMaster: result.daysToMaster ?? 0))
        }
    }

    /// Explication montrée après la réponse : la règle de la question, sinon la définition courte.
    var explanation: String {
        guard let question = current else { return "" }
        if !question.explanation.isEmpty { return question.explanation }
        return content.fiche(id: question.ficheID)?.shortDefinition ?? ""
    }

    func next() {
        guard case .answered = phase else { return }
        index += 1
        selected = nil
        justMastered = nil
        if index >= questions.count {
            finish()
        } else {
            phase = .question
            shownAt = now()
        }
    }

    private func finish() {
        phase = .finished
        if let session { recorder.finish(session, score: score, total: questions.count, at: now()) }
        analytics.track(.practiceCompleted(mode: mode, score: score, total: questions.count))
        sessionDays = recorder.sessionDays(last: 5, at: now())
        if isLevelTest {
            let level = recorder.saveLevelTest(score: score, outOf: questions.count, at: now())
            levelOutcome = LevelOutcome(level: level, pointsToNext: Rules.pointsToNextLevel(forLevelTestScore: score))
            analytics.track(.levelTestCompleted(score: score, level: level))
        }
        haptics.play(.celebration)
    }

    func restart() {
        seedOffset &+= 1
        start()
    }

    /// État d'une réponse à choix une fois la question répondue.
    func state(forChoice choice: Int) -> AnswerRow.State {
        guard let question = current, let selected, case .choice(let correctIndex) = question.correct else { return .idle }
        if choice == correctIndex { return .correct }
        return selected == .choice(choice) ? .wrong : .dimmed
    }

    /// État d'un bouton Juste / Fautif une fois la question répondue.
    func state(forTrueFalse value: Bool) -> AnswerRow.State {
        guard let question = current, let selected, case .trueFalse(let isJuste) = question.correct else { return .idle }
        if value == isJuste { return .correct }
        return selected == .trueFalse(value) ? .wrong : .dimmed
    }

    #if DEBUG
    /// `-autoplay` : joue la session jusqu'au bout par le même chemin que les touches (une réponse sur cinq fausse).
    func autoplay() async {
        if phase == .intro { start() }
        var turn = 0
        while phase == .question || isAnswered {
            if phase == .question, let question = current {
                turn += 1
                let wrong = turn % 5 == 0
                switch question.correct {
                case .choice(let index): select(.choice(wrong ? (index + 1) % question.choices.count : index))
                case .trueFalse(let value): select(.trueFalse(wrong ? !value : value))
                }
            }
            try? await Task.sleep(for: .milliseconds(250))
            if isAnswered { next() }
        }
    }

    private var isAnswered: Bool {
        if case .answered = phase { true } else { false }
    }
    #endif

    // MARK: Résultats

    /// "À retenir" depuis la liste des réponses (PRA-03).
    func saveToLearn(_ ficheID: String) {
        guard !savedToLearn.contains(ficheID) else { return }
        _ = progress.sort(ficheID, as: .toLearn, at: now())
        savedToLearn.insert(ficheID)
        haptics.play(.light)
    }
}
