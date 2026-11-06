import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import UserNotifications

/// Parcours d'onboarding (ONB-01 à ONB-11), ou sa partie mini test et rythme après MIG-01.
enum OnboardingFlow: Hashable {
    case full
    /// Depuis "Découvrir" de MIG-01 : ONB-05 à ONB-08.
    case afterMigration

    var steps: [OnboardingStep] {
        switch self {
        case .full: OnboardingStep.allCases
        case .afterMigration: [.testIntro, .test, .testResult, .dailyGoal]
        }
    }
}

enum OnboardingStep: String, CaseIterable {
    case welcome, attribution, age, goals, testIntro, test, testResult, dailyGoal, notifications, paywall, widget
}

@MainActor @Observable
final class OnboardingViewModel {
    let flow: OnboardingFlow
    let steps: [OnboardingStep]
    private(set) var index = 0
    private(set) var attribution: AttributionSource?
    private(set) var ageRange: AgeRange?
    private(set) var goals: Set<LearningGoal> = []
    private(set) var questions: [Question] = []
    private(set) var questionIndex = 0
    private(set) var selected: Question.Answer?
    private(set) var results: [(question: Question, correct: Bool)] = []
    var dailyGoal = Rules.defaultDailyGoal
    var reminderTime: Date
    var eveningReminder = true
    private(set) var notificationsGranted = false
    private(set) var showsWidgetSteps = false
    private var trackedSteps: Set<OnboardingStep> = []
    private(set) var isFinished = false

    private let content: ContentRepository
    private let store: any ProgressStoring
    private let entitlements: any PremiumProviding
    private let haptics: any HapticPlaying
    private let analytics: any Analytics
    private let now: () -> Date

    init(flow: OnboardingFlow, content: ContentRepository, store: any ProgressStoring, entitlements: any PremiumProviding,
         haptics: any HapticPlaying, analytics: any Analytics, now: @escaping () -> Date) {
        self.flow = flow; self.steps = flow.steps; self.content = content; self.store = store
        self.entitlements = entitlements; self.haptics = haptics; self.analytics = analytics; self.now = now
        self.reminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
        #if DEBUG
        if let name = DebugLaunch.value(after: "-onboardingStep"), let step = OnboardingStep(rawValue: name),
           let index = steps.firstIndex(of: step) {
            self.index = index
        }
        #endif
    }

    var step: OnboardingStep { steps[index] }
    var progress: Double { Double(index + 1) / Double(steps.count) }
    var isPremium: Bool { entitlements.isPremium }
    var score: Int { results.filter(\.correct).count }

    /// Retour possible, sauf après le paywall et pendant le mini test.
    var canGoBack: Bool {
        guard index > 0 else { return false }
        if let paywall = steps.firstIndex(of: .paywall), index > paywall { return false }
        return step != .test && step != .testResult
    }

    func onAppear() {
        trackStep()
    }

    /// `onboarding_step_viewed` une seule fois par étape, même si l'écran réapparaît.
    private func trackStep() {
        guard trackedSteps.insert(step).inserted else { return }
        analytics.track(.onboardingStepViewed(step: step.rawValue))
    }

    func next() {
        guard index + 1 < steps.count else { return finish() }
        index += 1
        haptics.play(.selection)
        trackStep()
        if step == .test { startTest() }
    }

    func back() {
        guard canGoBack else { return }
        index -= 1
        haptics.play(.selection)
    }

    // MARK: ONB-02 à ONB-04

    func choose(_ source: AttributionSource) {
        attribution = source
        next()
    }

    func choose(_ range: AgeRange) {
        ageRange = range
        next()
    }

    func toggle(_ goal: LearningGoal) {
        if goals.contains(goal) { goals.remove(goal) } else { goals.insert(goal) }
    }

    // MARK: ONB-06 mini test

    private func startTest() {
        questions = QuestionFactory(fiches: content.fiches).miniTest(seed: UInt64(bitPattern: Int64(now().timeIntervalSinceReferenceDate)))
        questionIndex = 0
        results = []
        selected = nil
        if questions.isEmpty { next() }
    }

    var currentQuestion: Question? { questions.indices.contains(questionIndex) ? questions[questionIndex] : nil }

    func answer(_ answer: Question.Answer) {
        guard selected == nil, let question = currentQuestion else { return }
        selected = answer
        let correct = question.isCorrect(answer)
        haptics.play(correct ? .success : .error)
        results.append((question, correct))
    }

    /// Réponse donnée à la question en cours : `nil` tant qu'on n'a pas répondu.
    var answeredCorrectly: Bool? {
        guard selected != nil, let last = results.last, last.question.id == currentQuestion?.id else { return nil }
        return last.correct
    }

    /// Explication de la question en cours, sinon la définition courte de la fiche.
    var explanation: String {
        guard let question = currentQuestion else { return "" }
        if !question.explanation.isEmpty { return question.explanation }
        return content.fiche(id: question.ficheID)?.shortDefinition ?? ""
    }

    /// Après lecture de l'explication : question suivante ou résultat.
    func continueTest() {
        guard selected != nil else { return }
        if questionIndex + 1 < questions.count {
            questionIndex += 1
            selected = nil
        } else {
            next()
        }
    }

    func state(forChoice choice: Int) -> AnswerRow.State {
        guard let question = currentQuestion, let selected, case .choice(let correctIndex) = question.correct else { return .idle }
        if choice == correctIndex { return .correct }
        return selected == .choice(choice) ? .wrong : .dimmed
    }

    func state(forTrueFalse value: Bool) -> AnswerRow.State {
        guard let question = currentQuestion, let selected, case .trueFalse(let isJuste) = question.correct else { return .idle }
        if value == isJuste { return .correct }
        return selected == .trueFalse(value) ? .wrong : .dimmed
    }

    // MARK: ONB-09 notifications

    func enableNotifications() async {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        notificationsGranted = granted
        haptics.play(granted ? .success : .light)
        next()
    }

    // MARK: ONB-11 widget

    func showWidgetSteps() {
        showsWidgetSteps = true
        haptics.play(.light)
    }

    // MARK: Fin

    func finish() {
        let level = questions.isEmpty ? nil : Rules.level(forMiniTestScore: score)
        // Le rythme de 10 fiches est réservé au premium.
        let goal = dailyGoal == Rules.premiumDailyGoal && !isPremium ? Rules.defaultDailyGoal : dailyGoal
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        store.completeOnboarding(OnboardingAnswers(
            attribution: attribution, ageRange: ageRange,
            goals: steps.contains(.goals) ? goals : nil,
            level: level, dailyGoal: goal,
            reminderMinute: notificationsGranted ? (components.hour ?? 9) * 60 + (components.minute ?? 0) : nil,
            eveningReminder: eveningReminder
        ))
        analytics.track(.onboardingCompleted(miniTestScore: questions.isEmpty ? nil : score, dailyGoal: goal, notificationsGranted: notificationsGranted))
        haptics.play(.celebration)
        isFinished = true
    }
}
