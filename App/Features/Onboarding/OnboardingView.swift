import SagaceCore
import SagaceUI
import SwiftUI

/// Onboarding plein écran (ONB-01 à ONB-11) : linéaire, barre de progression fine, retour possible sauf après le paywall.
struct OnboardingView: View {
    @State var viewModel: OnboardingViewModel
    let onFinish: () -> Void
    @Environment(ScreenFactory.self) private var factory
    /// iPad (`09_IPAD.md`) : une colonne centrée au milieu de l'écran.
    @State private var layout = LayoutWidth.compact

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.step != .paywall {
                topBar
            }
            Group {
                switch viewModel.step {
                case .welcome: welcome
                case .attribution: attribution
                case .age: age
                case .goals: goals
                case .testIntro: testIntro
                case .test: test
                case .testResult: testResult
                case .dailyGoal: dailyGoal
                case .notifications: notifications
                case .paywall: factory.paywall(.onboarding) { viewModel.next() }
                case .widget: widget
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            .id(viewModel.step)
        }
        .frame(
            maxWidth: layout.isRegular ? SagaceMetrics.focusWidth : .infinity,
            maxHeight: layout.isRegular ? SagaceMetrics.focusHeight : .infinity
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .readsLayoutWidth($layout)
        .environment(\.layoutWidth, layout)
        .background(viewModel.step == .paywall ? Color.vSurface : .vBackground)
        .animation(SagaceMotion.page, value: viewModel.step)
        .onAppear { viewModel.onAppear() }
        .onChange(of: viewModel.isFinished) { _, finished in if finished { onFinish() } }
    }

    // MARK: Barre du haut

    private var topBar: some View {
        HStack(spacing: 14) {
            CircleButton(systemImage: "chevron.left", accessibilityLabel: "Retour", size: 36) { viewModel.back() }
                .opacity(viewModel.canGoBack ? 1 : 0)
                .disabled(!viewModel.canGoBack)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.vSurfaceSelected)
                    Capsule().fill(.vTextPrimary).frame(width: proxy.size.width * viewModel.progress)
                }
            }
            .frame(height: 4)
            .animation(SagaceMotion.select, value: viewModel.progress)
            .accessibilityHidden(true)
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, SagaceMetrics.pageMargin)
        .padding(.top, 8)
    }

    // MARK: Gabarit

    private func page<Content: View, Footer: View>(
        title: LocalizedStringKey? = nil, subtitle: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let title {
                        Text(title).textStyle(.title).fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                    }
                    if let subtitle {
                        Text(subtitle).textStyle(.body)
                    }
                    content()
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.top, 24)
            }
            VStack(spacing: 8) { footer() }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.bottom, 12)
        }
    }

    private func illustration(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .symbolVariant(.fill)
            .font(.system(size: layout.isRegular ? 110 : 76))
            .foregroundStyle(.vBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .accessibilityHidden(true)
    }

    private func skipButton() -> some View {
        Button { viewModel.next() } label: {
            Text("Passer").fontStyle(.button).foregroundStyle(.vTextSecondary).frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    // MARK: ONB-01 Bienvenue

    private var welcome: some View {
        page {
            illustration("character.book.closed")
            Text("Le mot juste, chaque jour.").textStyle(.hero).fixedSize(horizontal: false, vertical: true)
            Text("Quelques minutes par jour pour parler et écrire avec précision. Sans jargon, sans mots pédants.")
                .textStyle(.definition)
        } footer: {
            PrimaryButton("Commencer") { viewModel.next() }
        }
    }

    // MARK: ONB-02 Attribution

    private var attribution: some View {
        let options: [(AttributionSource, LocalizedStringKey)] = [
            (.tiktok, "TikTok"), (.instagram, "Instagram"), (.facebook, "Facebook"), (.youtube, "YouTube"),
            (.appStore, "App Store"), (.webSearch, "Recherche web"), (.friend, "Un proche"), (.other, "Autre"),
        ]
        return page(title: "Comment avez-vous connu Sagace ?") {
            VStack(spacing: SagaceMetrics.rowSpacing) {
                ForEach(options, id: \.0) { source, title in
                    OptionRow(title, isSelected: viewModel.attribution == source) { viewModel.choose(source) }
                }
            }
        } footer: { skipButton() }
    }

    // MARK: ONB-03 Âge

    private var age: some View {
        let options: [(AgeRange, LocalizedStringKey)] = [
            (.age13to17, "13 à 17"), (.age18to24, "18 à 24"), (.age25to34, "25 à 34"),
            (.age35to44, "35 à 44"), (.age45to54, "45 à 54"), (.age55plus, "55 ans et plus"),
        ]
        return page(title: "Quel âge avez-vous ?", subtitle: "Pour adapter les exemples à votre quotidien.") {
            VStack(spacing: SagaceMetrics.rowSpacing) {
                ForEach(options, id: \.0) { range, title in
                    OptionRow(title, isSelected: viewModel.ageRange == range) { viewModel.choose(range) }
                }
            }
        } footer: { skipButton() }
    }

    // MARK: ONB-04 Objectifs

    private var goals: some View {
        let options: [(LearningGoal, LocalizedStringKey, String)] = [
            (.ecrireTravail, "Écrire au travail", "envelope"), (.parlerAssurance, "Parler avec assurance", "person.wave.2"),
            (.examen, "Réussir un examen ou un concours", "graduationcap"), (.enfants, "Aider mes enfants", "figure.and.child.holdinghands"),
            (.curiosite, "Par curiosité", "sparkles"),
        ]
        return page(title: "Qu'aimeriez-vous améliorer ?", subtitle: "Plusieurs choix possibles.") {
            VStack(spacing: SagaceMetrics.rowSpacing) {
                ForEach(options, id: \.0) { goal, title, symbol in
                    let selected = viewModel.goals.contains(goal)
                    OptionRow(title, systemImage: selected ? "checkmark.circle.fill" : symbol, isSelected: selected, haptic: .selection) {
                        viewModel.toggle(goal)
                    }
                }
            }
        } footer: {
            PrimaryButton("Continuer") { viewModel.next() }
                .disabled(viewModel.goals.isEmpty)
        }
    }

    // MARK: ONB-05 à ONB-07 Mini test

    private var testIntro: some View {
        page {
            illustration("graduationcap")
            Text("Petit test : 5 pièges du quotidien.").textStyle(.title)
            Text("Une minute, pour savoir par où commencer.").textStyle(.definition)
        } footer: {
            PrimaryButton("C'est parti") { viewModel.next() }
        }
    }

    private var test: some View {
        VStack(spacing: 18) {
            ProgressDots(total: viewModel.questions.count, completed: viewModel.results.count)
            if let question = viewModel.currentQuestion {
                ScrollView {
                    VStack(spacing: 18) {
                        QuestionCard(label: Text(question.game.title), prompt: question.prompt, isSingleWord: question.game == .sens)
                        if question.game == .justeOuFautif {
                            HStack(spacing: 12) {
                                AnswerRow(localized: "Juste", state: viewModel.state(forTrueFalse: true)) { viewModel.answer(.trueFalse(true)) }
                                    .trueFalseShortcut(true)
                                AnswerRow(localized: "Fautif", state: viewModel.state(forTrueFalse: false)) { viewModel.answer(.trueFalse(false)) }
                                    .trueFalseShortcut(false)
                            }
                        } else {
                            VStack(spacing: SagaceMetrics.rowSpacing) {
                                ForEach(question.choices.indices, id: \.self) { index in
                                    AnswerRow(question.choices[index], state: viewModel.state(forChoice: index)) { viewModel.answer(.choice(index)) }
                                        .answerShortcut(index)
                                }
                            }
                        }
                        if let correct = viewModel.answeredCorrectly {
                            AnswerFeedback(isCorrect: correct, correctAnswer: question.correctChoice, explanation: viewModel.explanation,
                                           onContinue: viewModel.continueTest)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 12)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(.top, for: .initialOffset)
                .defaultScrollAnchor(.bottom, for: .sizeChanges)
            }
        }
        .animation(SagaceMotion.select, value: viewModel.answeredCorrectly)
        .padding(.horizontal, SagaceMetrics.pageMargin)
        .padding(.top, 24)
    }

    private var testResult: some View {
        page {
            ScoreBlock(score: viewModel.score, total: viewModel.questions.count, subtitle: Text(resultPhrase), days: [])
                .padding(.vertical, 12)
            VStack(spacing: SagaceMetrics.rowSpacing) {
                ForEach(viewModel.results, id: \.question.id) { result in
                    HStack(spacing: 12) {
                        Image(systemName: result.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.correct ? Color.vCorrect : .vIncorrect)
                        Text(verbatim: result.question.correctChoice.map { "\(result.question.prompt) → \($0)" } ?? result.question.prompt)
                            .textStyle(.body)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
            }
        } footer: {
            PrimaryButton("Continuer") { viewModel.next() }
        }
    }

    private var resultPhrase: LocalizedStringKey {
        switch viewModel.score {
        case 5...: "Impressionnant. On va viser les pièges plus fins."
        case 3...4: "Bien vu. Quelques pièges vous ont échappé, c'est exactement ce qu'on va travailler."
        default: "C'est normal : ces pièges trompent la plupart des gens. Vous allez vite progresser."
        }
    }

    // MARK: ONB-08 Rythme

    private var dailyGoal: some View {
        page(title: "Combien de fiches par jour ?") {
            VStack(spacing: SagaceMetrics.rowSpacing) {
                goalRow(3, title: "3 fiches", description: "Tranquille, 1 minute")
                goalRow(5, title: "5 fiches", description: "Régulier, 3 minutes")
                goalRow(10, title: "10 fiches", description: "Intensif, 6 minutes", isPro: true)
            }
        } footer: {
            PrimaryButton("Continuer") { viewModel.next() }
        }
    }

    private func goalRow(_ goal: Int, title: LocalizedStringKey, description: LocalizedStringKey, isPro: Bool = false) -> some View {
        OptionRow(title, description: description, detail: isPro ? "PRO" : nil, isSelected: viewModel.dailyGoal == goal) {
            viewModel.dailyGoal = goal
        }
    }

    // MARK: ONB-09 Notifications

    private var notifications: some View {
        page(title: "Une fiche au bon moment.") {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "character.book.closed.fill")
                    .foregroundStyle(.vOnAccent)
                    .frame(width: 38, height: 38)
                    .background(.vBlue, in: .rect(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "Sagace").font(.subheadline.weight(.semibold)).foregroundStyle(.vTextPrimary)
                    Text("éminent ou imminent ? Le départ est imminent, l'invité est éminent.").font(.subheadline).foregroundStyle(.vTextPrimary)
                }
            }
            .padding(14)
            .background(.vSurface, in: .rect(cornerRadius: 22, style: .continuous))
            .cardShadow()
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)
            DatePicker(selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute) {
                Text("Heure de la fiche").fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
            }
            .padding(16)
            .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
            Toggle(isOn: $viewModel.eveningReminder) {
                Text("Un rappel le soir si la série est en danger").fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
            }
            .tint(.vTextPrimary)
            .padding(16)
            .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
        } footer: {
            PrimaryButton("Activer les notifications", systemImage: "bell.fill", haptic: nil) {
                Task { await viewModel.enableNotifications() }
            }
            Button { viewModel.next() } label: {
                Text("Plus tard").fontStyle(.button).foregroundStyle(.vTextSecondary).frame(maxWidth: .infinity, minHeight: 44)
            }
        }
    }

    // MARK: ONB-11 Widget

    private var widget: some View {
        page {
            illustration("iphone.gen3")
            Text("Une fiche sur votre écran d'accueil.").textStyle(.title)
            Text("Touchez longuement l'écran d'accueil, puis Modifier, puis Ajouter un widget, et cherchez Sagace.")
                .textStyle(.definition)
            if viewModel.showsWidgetSteps {
                VStack(alignment: .leading, spacing: 12) {
                    widgetStep(1, "Touchez longuement un espace vide de l'écran d'accueil.")
                    widgetStep(2, "Touchez Modifier, puis Ajouter un widget.")
                    widgetStep(3, "Cherchez Sagace et choisissez la fiche du jour.")
                }
                .padding(18)
                .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
            }
        } footer: {
            if viewModel.showsWidgetSteps {
                PrimaryButton("Terminé") { viewModel.finish() }
            } else {
                PrimaryButton("Installer le widget", haptic: nil) { viewModel.showWidgetSteps() }
                Button { viewModel.finish() } label: {
                    Text("Plus tard").fontStyle(.button).foregroundStyle(.vTextSecondary).frame(maxWidth: .infinity, minHeight: 44)
                }
            }
        }
    }

    private func widgetStep(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(verbatim: "\(number)")
                .font(.system(size: 15, weight: .heavy).monospacedDigit())
                .foregroundStyle(.vOnInverse)
                .frame(width: 26, height: 26)
                .background(.vInverse, in: .circle)
            Text(text).textStyle(.definition)
        }
    }
}
