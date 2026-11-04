#if DEBUG
import Foundation
import Observation
import SagaceCore
import SagaceUI
import SwiftUI

/// Options de lancement pour tester un écran directement (debug uniquement).
enum DebugLaunch {
    static func value(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    static var autoplay: Bool { ProcessInfo.processInfo.arguments.contains("-autoplay") }

    /// `-debugSheet practice | paywall | levelTest | game:<jeu> | challenge:<rush|sprint|perfection>`
    static var sheet: Sheet? {
        guard let value = value(after: "-debugSheet") else { return nil }
        let parts = value.split(separator: ":").map(String.init)
        switch parts.first {
        case "practice": return .practice
        case "paywall": return .paywall(.crown)
        case "levelTest": return .levelTest
        case "crossword": return .crossword
        case "game": return parts.last.flatMap(GameType.init(rawValue:)).map { .session(.game($0)) }
        case "challenge":
            return ["rush": ChallengeState.Kind.rush, "sprint": .sprint, "perfection": .perfection][parts.last ?? ""].map(Sheet.challenge)
        default: return nil
        }
    }
}

enum DesignSystemDemo {
    /// Argument de lancement qui ouvre la démo directement (captures, vérifications).
    static let launchArgument = "-designSystemDemo"

    static var isRequestedAtLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }
}

/// État de la page de démonstration de `SagaceUI` (debug uniquement).
@MainActor @Observable final class DesignSystemDemoViewModel {
    enum Appearance: CaseIterable, Hashable {
        case automatic, light, dark

        var colorScheme: ColorScheme? {
            switch self {
            case .automatic: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    enum Plan: Hashable { case yearly, lifetime }

    enum SettingsTab: Hashable { case content, game, effects, notifications, account }

    enum Filter: Hashable { case all, level(Level) }

    enum Section: String, Hashable { case colors, type, card, buttons, chips, options, sheet, haptics }

    var appearance: Appearance
    private(set) var selectedLevel: Level = .intermediaire
    private(set) var selectedPlan: Plan = .yearly
    private(set) var selectedDailyGoal = Rules.defaultDailyGoal
    private(set) var filter: Filter = .all
    private(set) var isBookmarked = false
    private(set) var isKnown = false
    var settingsTab: SettingsTab = .content
    var isShowingSheet = false
    /// Section affichée à l'ouverture (`-demoSection <nom>`).
    let initialSection: Section?

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        appearance = arguments.contains("-dark") ? .dark : arguments.contains("-light") ? .light : .automatic
        isShowingSheet = arguments.contains("-demoSheet")
        if let index = arguments.firstIndex(of: "-demoSection"), arguments.indices.contains(index + 1) {
            initialSection = Section(rawValue: arguments[index + 1])
        } else {
            initialSection = nil
        }
    }

    func select(_ level: Level) { selectedLevel = level }
    func select(_ plan: Plan) { selectedPlan = plan }
    func selectDailyGoal(_ goal: Int) { selectedDailyGoal = goal }
    func select(_ filter: Filter) { self.filter = filter }
    func toggleBookmark() { isBookmarked.toggle() }
    func toggleKnown() { isKnown.toggle() }
    func showSheet() { isShowingSheet = true }
}
#endif
