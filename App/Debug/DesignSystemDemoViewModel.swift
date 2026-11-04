#if DEBUG
import Foundation
import Observation
import SagaceCore
import SagaceUI
import SwiftUI

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
