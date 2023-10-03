//
//  SettingsView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 20/09/2023.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    
    let termsAndConditionsURL = URL(string: "https://www.notion.so/APPLICATION-TERMS-AND-CONDITIONS-OF-USE-AND-PRIVACY-POLICY-431520373299481a97353288b54489f5?pvs=4")!
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var storeKitManager : StoreKitManager
    
    @ObservedObject var hapticManager = HapticManager.shared
    
    @State private var isShowingPremiumView : Bool = false
    
    @State private var isShareSheetShowing = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Title
                
                if !storeKitManager.hasUnlockedPremium { BuyPremiumButton.padding() }

                List {
                    SettingsSection
                }
            }
            .navigationBarItems(leading: CancelButton)
            .navigationDestination(isPresented: $isShowingPremiumView) {
                PremiumView()
            }
        }
    }
    
    var CancelButton : some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Done")
                .foregroundColor(.primary)
                .font(.subheadline)
        }
    }

    var Title : some View {
        HStack() {
            Text("Words")
                .font(.title)
                .bold()
            Spacer()
        }
        .padding(.leading)
    }

    var BuyPremiumButton : some View {
        CustomButtonMarked(text: "Try Words Free", action: { isShowingPremiumView.toggle()})
    }

    var SettingsSection : some View {
        Section("Settings") {
            Button(action: {
                self.isShareSheetShowing.toggle()
            }) {
                HStack(spacing: 20) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Words")
                }
                .foregroundStyle(.black)
            }
            .sheet(isPresented: $isShareSheetShowing) {
                ShareSheet(activityItems: ["Check this app"])
            }
            
            NavigationLink(destination: ChangeIconView()) {
                HStack(spacing: 20) {
                    Image(systemName: "square.fill")
                    Text("Change Icon")
                }
            }
            
            HStack {
                Image(systemName: hapticManager.isHapticEnabled ? "water.waves" : "water.waves.slash")
                Toggle("Haptic", isOn: $hapticManager.isHapticEnabled)
            }
            
            Link(destination: termsAndConditionsURL) {
                HStack(spacing: 20) {
                    Image(systemName: "doc.text.fill")
                    Text("Terms & Conditions")
                }
                .foregroundStyle(.black)
            }
            
            NavigationLink(destination: PrivacyPolicyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                    Text("Privacy Policy")
                }
            }
            
//            NavigationLink(destination: HapticTestView()) {
//                HStack(spacing: 20) {
//                    Image(systemName: "phone")
//                    Text("Haptic Test View")
//                }
//            }
            
            NavigationLink(destination: FeedbackView()) {
                HStack(spacing: 20) {
                    Image(systemName: "bubble.right.fill")
                    Text("Please leave us a feedback")
                }
            }
            
            
            Button(action: {
                Task {
                    do {
                        try await AppStore.sync()
                    } catch {
                        print(error)
                    }
                }
            }) {
                HStack(spacing: 20) {
                    Image(systemName: "purchased")
                    Text("Restore purchase(s)")
                }
                .foregroundStyle(.black)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(StoreKitManager())
    }
}



    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]
        let applicationActivities: [UIActivity]? = nil

        func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
            let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
            return controller
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {}
    }
