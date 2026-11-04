import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftUI

/// Défis Rush, Sprint, Perfection (PRA-04 à 06). Les règles sont dans `ChallengeState`, l'horloge ici.
@MainActor @Observable
final class ChallengeViewModel {
    enum Phase: Equatable { case intro, playing, over, locked }

    let kind: ChallengeState.Kind
    private(set) var phase: Phase = .intro
    private(set) var state: ChallengeState
    private(set) var current: Question?
    private(set) var selected: Question.Answer?
    private(set) var record: Int?
    private(set) var isNewRecord = false

    private let content: ContentRepository
    private let factory: QuestionFactory
    private let recorder: any PracticeRecording
    private let entitlements: any PremiumProviding
    private let haptics: any HapticPlaying
    private let analytics: any Analytics
    private let now: () -> Date
    private var queue: [Question] = []
    private var session: PracticeSession?
    private var shownAt = Date()
    private var clock: Task<Void, Never>?
    private var round: UInt64 = 0

    init(kind: ChallengeState.Kind, content: ContentRepository, recorder: any PracticeRecording, entitlements: any PremiumProviding,
         haptics: any HapticPlaying, analytics: any Analytics, now: @escaping () -> Date) {
        self.kind = kind; self.content = content; self.recorder = recorder; self.entitlements = entitlements
        self.haptics = haptics; self.analytics = analytics; self.now = now
        self.factory = QuestionFactory(fiches: content.fiches)
        self.state = ChallengeState(kind: kind)
    }

    func onAppear() {
        record = recorder.bestScore(for: kind.mode)
    }

    func begin() {
        guard PracticeStats.canStartGame(isPremium: entitlements.isPremium, gameSessionsToday: recorder.gameSessionsToday(at: now())) else {
            phase = .locked
            return
        }
        state = ChallengeState(kind: kind)
        queue = []
        isNewRecord = false
        session = recorder.start(kind.mode, at: now())
        analytics.track(.practiceStarted(mode: kind.mode))
        phase = .playing
        advance()
        startClock()
    }

    /// Questions sans fin : on reconstitue la file quand elle est vide.
    private func advance() {
        if queue.isEmpty {
            round &+= 1
            queue = factory.mixed(from: content.fiches, count: content.fiches.count, games: kind.games,
                                  seed: UInt64(bitPattern: Int64(now().timeIntervalSinceReferenceDate)) &+ round)
        }
        current = queue.isEmpty ? nil : queue.removeFirst()
        selected = nil
        shownAt = now()
    }

    private func startClock() {
        clock?.cancel()
        guard kind != .perfection else { return }
        clock = Task { [weak self] in
            let tick = Duration.milliseconds(100)
            while !Task.isCancelled {
                try? await Task.sleep(for: tick)
                guard let self, self.phase == .playing else { return }
                self.handle(self.state.tick(0.1))
            }
        }
    }

    func select(_ answer: Question.Answer) {
        guard phase == .playing, selected == nil, let question = current, let session else { return }
        selected = answer
        let correct = question.isCorrect(answer)
        recorder.record(question, correct: correct, responseMs: Int(now().timeIntervalSince(shownAt) * 1000), in: session, at: now())
        handle(state.answer(correct: correct))
        guard phase == .playing else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            if phase == .playing, current?.id == question.id { advance() }
        }
    }

    private func handle(_ events: [ChallengeState.Event]) {
        for event in events {
            switch event {
            case .correct: haptics.play(.success)
            case .wrong: haptics.play(.error)
            case .lostLife: haptics.play(.heavy)
            case .timedOut: advance()
            case .ended: end()
            }
        }
    }

    private func end() {
        clock?.cancel()
        phase = .over
        if let session { recorder.finish(session, score: state.score, total: state.answered, at: now()) }
        analytics.track(.practiceCompleted(mode: kind.mode, score: state.score, total: state.answered))
        isNewRecord = state.score > (record ?? 0)
        record = max(record ?? 0, state.score)
        haptics.play(.celebration)
    }

    #if DEBUG
    /// `-autoplay` : bonnes réponses puis erreurs, jusqu'à la fin du défi.
    func autoplay() async {
        begin()
        var turn = 0
        while phase == .playing {
            if selected == nil, let question = current {
                turn += 1
                let wrong = turn > 6
                switch question.correct {
                case .choice(let index): select(.choice(wrong ? (index + 1) % question.choices.count : index))
                case .trueFalse(let value): select(.trueFalse(wrong ? !value : value))
                }
            }
            try? await Task.sleep(for: .milliseconds(kind == .sprint ? 2_000 : 600))
        }
    }
    #endif

    func quit() {
        clock?.cancel()
    }

    func state(forChoice choice: Int) -> AnswerRow.State {
        guard let question = current, let selected, case .choice(let correctIndex) = question.correct else { return .idle }
        if choice == correctIndex { return .correct }
        return selected == .choice(choice) ? .wrong : .dimmed
    }

    func state(forTrueFalse value: Bool) -> AnswerRow.State {
        guard let question = current, let selected, case .trueFalse(let isJuste) = question.correct else { return .idle }
        if value == isJuste { return .correct }
        return selected == .trueFalse(value) ? .wrong : .dimmed
    }
}

struct ChallengeView: View {
    @State var viewModel: ChallengeViewModel
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetContainer(viewModel.kind.title, systemImage: viewModel.kind.symbol) {
            Group {
                switch viewModel.phase {
                case .intro: intro
                case .playing: playing
                case .over: over
                case .locked: locked
                }
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
            .padding(.bottom, 12)
        }
        .stackedPaywall(router)
        .interactiveDismissDisabled(viewModel.phase == .playing)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.quit() }
        #if DEBUG
        .task { if DebugLaunch.autoplay { await viewModel.autoplay() } }
        #endif
    }

    private var intro: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: viewModel.kind.symbol)
                .symbolVariant(.fill)
                .font(.system(size: 64))
                .foregroundStyle(.vBlue)
                .accessibilityHidden(true)
            Text(viewModel.kind.rules).textStyle(.definition).multilineTextAlignment(.center)
            if let record = viewModel.record {
                Chip("Record : \(record)", systemImage: "trophy")
            }
            Spacer()
            PrimaryButton("Commencer") { viewModel.begin() }
        }
    }

    private var playing: some View {
        VStack(spacing: 16) {
            HStack {
                if viewModel.kind == .rush {
                    LivesView(lives: viewModel.state.lives, maximum: Rules.rushLives)
                }
                Spacer()
                Text("\(viewModel.state.correct)")
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .foregroundStyle(.vTextPrimary)
                    .accessibilityLabel(Text("\(viewModel.state.correct) bonnes réponses"))
            }
            if viewModel.kind != .perfection {
                TimerBar(fraction: viewModel.state.timeFraction)
            }
            if let question = viewModel.current {
                QuestionCard(label: Text(question.game.title), prompt: question.prompt, isSingleWord: question.game == .sens)
                if question.game == .justeOuFautif {
                    HStack(spacing: 12) {
                        AnswerRow(localized: "Juste", state: viewModel.state(forTrueFalse: true)) { viewModel.select(.trueFalse(true)) }
                        AnswerRow(localized: "Fautif", state: viewModel.state(forTrueFalse: false)) { viewModel.select(.trueFalse(false)) }
                    }
                } else {
                    VStack(spacing: SagaceMetrics.rowSpacing) {
                        ForEach(question.choices.indices, id: \.self) { index in
                            AnswerRow(question.choices[index], state: viewModel.state(forChoice: index)) { viewModel.select(.choice(index)) }
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    /// Fin de défi, façon "Game Over".
    private var over: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: viewModel.isNewRecord ? "trophy.fill" : viewModel.kind.symbol)
                .symbolVariant(.fill)
                .font(.system(size: 56))
                .foregroundStyle(viewModel.isNewRecord ? Color.vLevelAvance : .vTextPrimary)
                .accessibilityHidden(true)
            Group {
                switch viewModel.state.endReason {
                case .noLivesLeft: Text("Plus de vies !")
                case .timeUp: Text("Temps écoulé !")
                case .firstMistake, nil: Text("Série terminée à \(viewModel.state.score).")
                }
            }
            .textStyle(.title)
            Group {
                switch viewModel.kind {
                case .rush: Text("\(viewModel.state.correct) bonnes réponses sur \(viewModel.state.answered).")
                case .sprint: Text("\(viewModel.state.correct) bonnes réponses.")
                case .perfection: Text("\(viewModel.state.correct) bonnes réponses d'affilée.")
                }
            }
            .textStyle(.definition)
            if let record = viewModel.record {
                Chip(viewModel.isNewRecord ? "Nouveau record : \(record)" : "Record : \(record)", systemImage: "trophy")
            }
            Spacer()
            PrimaryButton("Rejouer", systemImage: "arrow.counterclockwise") { viewModel.begin() }
            SecondaryButton("Terminer") { dismiss() }
        }
    }

    private var locked: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Votre session gratuite du jour est jouée.").textStyle(.definition).multilineTextAlignment(.center)
            ProBanner { router.stackedPaywall = .proBanner }
            Spacer()
            SecondaryButton("Plus tard") { dismiss() }
        }
    }
}
