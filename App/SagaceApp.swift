import SagaceUI
import SwiftUI

@main
struct SagaceApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.haptics, HapticsService.shared)
        }
    }
}
