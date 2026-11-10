import SagaceCore
import SagaceUI
import SwiftUI

/// Session de jeu (PRA-02, PRA-03) et test de précision (PRA-07, PRA-08).
struct PracticeSessionView: View {
    @State var viewModel: PracticeSessionViewModel
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GameContainer(title: viewModel.current.map { Text($0.game.title) }) {
            Group {
                switch viewModel.phase {
                case .intro: intro
                case .loading: GameLoadingView()
                case .question, .answered: questionScreen
                case .finished: results
                case .locked: locked
                case .empty:
                    EmptyState(systemImage: "rectangle.stack", text: "Pas encore assez de fiches pour ce jeu.")
                }
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
            .readableColumn(SagaceMetrics.focusWidth)
        }
        .stackedPaywall(router)
        .interactiveDismissDisabled(viewModel.isInProgress)
        .task {
            if !viewModel.isLevelTest, viewModel.questions.isEmpty { await viewModel.start() }
            #if DEBUG
            if DebugLaunch.autoplay { await viewModel.autoplay() }
            #endif
        }
        .onDisappear { viewModel.cancelPreparation() }
    }

    // MARK: Test : introduction (PRA-07)

    private var intro: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 64))
                .foregroundStyle(.vBlue)
                .accessibilityHidden(true)
            Text("Test de précision").textStyle(.title)
            Text("30 questions, environ 5 minutes. Pour mesurer votre précision et adapter vos fiches.")
                .textStyle(.definition)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton("Commencer") { Task { await viewModel.start() } }
        }
        .padding(.bottom, 8)
    }

    // MARK: Question (PRA-02)

    /// Si l'explication ne tient pas, la page défile et reste calée en bas sur le bouton Continuer.
    private var questionScreen: some View {
        VStack(spacing: 18) {
            ProgressDots(total: viewModel.questions.count, completed: viewModel.completedCount)
            if let question = viewModel.current {
                GameRoundLayout {
                    QuestionCard(prompt: question.prompt, isSingleWord: question.game == .sens)
                        .offset(x: dragOffset)
                        .rotationEffect(.degrees(dragOffset / 40))
                        .gesture(question.game == .justeOuFautif ? swipeToAnswer : nil)
                } controls: {
                    VStack(spacing: 18) {
                        answers(for: question)
                        if case .answered(let correct) = viewModel.phase {
                            AnswerFeedback(isCorrect: correct, correctAnswer: question.correctChoice, explanation: viewModel.explanation,
                                           mastered: viewModel.justMastered, onContinue: viewModel.next)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .id(question.id)
            }
        }
        .animation(SagaceMotion.select, value: viewModel.phase)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func answers(for question: Question) -> some View {
        if question.game == .justeOuFautif {
            HStack(spacing: 12) {
                AnswerRow(localized: "Juste", state: viewModel.state(forTrueFalse: true)) { viewModel.select(.trueFalse(true)) }
                    .accessibilityIdentifier("answer.juste")
                    .trueFalseShortcut(true)
                AnswerRow(localized: "Fautif", state: viewModel.state(forTrueFalse: false)) { viewModel.select(.trueFalse(false)) }
                    .accessibilityIdentifier("answer.fautif")
                    .trueFalseShortcut(false)
            }
        } else {
            VStack(spacing: SagaceMetrics.rowSpacing) {
                ForEach(question.choices.indices, id: \.self) { index in
                    AnswerRow(question.choices[index], state: viewModel.state(forChoice: index)) { viewModel.select(.choice(index)) }
                        .accessibilityIdentifier("answer.\(index)")
                        .answerShortcut(index)
                }
            }
        }
    }

    /// Juste ou fautif : glisser à droite pour Juste, à gauche pour Fautif.
    private var swipeToAnswer: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { dragOffset = $0.translation.width }
            .onEnded { value in
                if abs(value.translation.width) > 100 { viewModel.select(.trueFalse(value.translation.width > 0)) }
                withAnimation(SagaceMotion.press) { dragOffset = 0 }
            }
    }

    // MARK: Résultats (PRA-03, PRA-08)

    private var results: some View {
        ScrollView {
            VStack(spacing: 22) {
                ScoreBlock(score: viewModel.score, total: viewModel.questions.count, subtitle: Text("bonnes réponses"), days: viewModel.sessionDays)
                    .padding(.top, 8)
                if let outcome = viewModel.levelOutcome {
                    LevelResultView(outcome: outcome, score: viewModel.score, total: viewModel.questions.count)
                }
                VStack(spacing: SagaceMetrics.rowSpacing) {
                    ForEach(viewModel.answered) { item in
                        answerRow(item)
                    }
                }
                HStack(spacing: 12) {
                    if !viewModel.isLevelTest {
                        PrimaryButton("Rejouer", systemImage: "arrow.counterclockwise") { Task { await viewModel.restart() } }
                    }
                    SecondaryButton("Terminer") { dismiss() }
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func answerRow(_ item: PracticeSessionViewModel.Answered) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(item.isCorrect ? Color.vCorrect : .vIncorrect)
                .font(.system(size: 20))
                .accessibilityLabel(item.isCorrect ? Text("Juste") : Text("Faux"))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.fiche?.headword ?? item.question.prompt).textStyle(.rowTitle)
                Text(item.question.game.title).textStyle(.meta)
            }
            Spacer()
            CircleButton(systemImage: "bookmark", accessibilityLabel: "À retenir", size: 40,
                         isActive: viewModel.savedToLearn.contains(item.question.ficheID), haptic: nil) {
                viewModel.saveToLearn(item.question.ficheID)
            }
        }
        .padding(14)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
    }

    // MARK: Limite gratuite

    private var locked: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 52))
                .foregroundStyle(.vTextSecondary)
                .accessibilityHidden(true)
            Text("Votre session gratuite du jour est jouée.")
                .textStyle(.definition)
                .multilineTextAlignment(.center)
            ProBanner { router.stackedPaywall = .proBanner }
            Spacer()
            SecondaryButton("Plus tard") { dismiss() }
        }
        .padding(.bottom, 8)
    }
}

/// Résultat de niveau (PRA-08) : les 5 lignes de niveau, celle de l'utilisateur dépliée.
struct LevelResultView: View {
    let outcome: PracticeSessionViewModel.LevelOutcome
    let score: Int
    let total: Int

    var body: some View {
        VStack(spacing: SagaceMetrics.rowSpacing) {
            ForEach(Level.allCases, id: \.self) { level in
                OptionRow(
                    level.title,
                    description: level.summary,
                    systemImage: level.symbol,
                    iconTint: level == .debutant ? level.tint : .vTextSecondary,
                    selectionStyle: .fill(background: level.selectedBackground, foreground: level.selectedForeground),
                    isSelected: level == outcome.level,
                    boldOnSelection: level.needsBoldText,
                    haptic: nil
                ) {}
                .allowsHitTesting(false)
            }
            Group {
                if let points = outcome.pointsToNext, let next = outcome.level.next {
                    Text("Score : \(score) / \(total) · \(points) points avant \(Text(next.title))")
                } else {
                    Text("Score : \(score) / \(total)")
                }
            }
            .textStyle(.body)
            .padding(.top, 6)
        }
    }
}
