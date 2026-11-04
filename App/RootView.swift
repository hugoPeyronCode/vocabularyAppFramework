import SagaceUI
import SwiftUI

/// Racine provisoire du jalon M0. Le feed la remplace au jalon M1.
struct RootView: View {
    #if DEBUG
    @State private var isShowingDemo = DesignSystemDemo.isRequestedAtLaunch
    #endif

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("Sagace")
                .textStyle(.hero)
            Text("Le mot juste, chaque jour.")
                .textStyle(.body)
            Spacer()
            #if DEBUG
            SecondaryButton("Design system", systemImage: "paintpalette") { isShowingDemo = true }
            #endif
        }
        .padding(SagaceMetrics.pageMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.vBackground)
        #if DEBUG
        .fullScreenCover(isPresented: $isShowingDemo) {
            DesignSystemDemoView()
        }
        #endif
    }
}

#Preview {
    RootView()
}
