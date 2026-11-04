import SagaceUI
import SwiftUI
import TipKit

@main
struct SagaceApp: App {
    @State private var dependencies = AppDependencies()

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-resetTips") { try? Tips.resetDatastore() }
        if arguments.contains("-hideTips") { Tips.hideAllTipsForTesting() }
        #endif
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .environment(dependencies.router)
                .environment(\.haptics, dependencies.haptics)
        }
        .backgroundTask(.appRefresh(ReminderScheduler.refreshTaskIdentifier)) {
            await dependencies.reminders.reschedule()
            await MainActor.run { dependencies.reminders.submitBackgroundRefresh() }
        }
    }
}
