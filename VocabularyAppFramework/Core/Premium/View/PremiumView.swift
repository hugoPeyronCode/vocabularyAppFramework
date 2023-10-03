//
//  PremiumView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.

// hugosandboxtester@gmail.com
// @@BXa?oe?C3M7Cmk

// Privacy policy link :https://www.notion.so/APPLICATION-TERMS-AND-CONDITIONS-OF-USE-AND-PRIVACY-POLICY-431520373299481a97353288b54489f5?pvs=4

import SwiftUI
import StoreKit

struct PremiumView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject private var storeKitManager : StoreKitManager
    
    let termsAndConditionsURL = URL(string: "https://www.notion.so/APPLICATION-TERMS-AND-CONDITIONS-OF-USE-AND-PRIVACY-POLICY-431520373299481a97353288b54489f5?pvs=4")!
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                if storeKitManager.isLoading {
                    ProgressView() // Show loading symbol when isLoading is true
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .scaleEffect(2)
                }
                
                VStack(spacing: 40) {
                    
                    HeaderText
                    
                    Crown
                    
                    Text(storeKitManager.hasUnlockedPremium ? "You're premium" : "Unlock everything")
                        .font(.title2)
                        .bold()
                    
                    AdvantagesList
                    
                    Spacer()
                    
                    ForEach(storeKitManager.products) { product in
                        
                        Text("\(product.displayPrice) per year ")
                            .foregroundColor(.black)
                            .font(.subheadline)
                        
                        CustomButtonMarked(text: "Continue", action: {
                            
                            HapticManager.shared.generateFeedback(for: .successLight)
                            
                            Task {
                                do {
                                    try await storeKitManager.purchase(product)
                                } catch {
                                    print(error)
                                }
                            }
                        })
                        .padding()
                    }
                }
                .navigationBarItems(leading: CancelButton)
                .navigationBarBackButtonHidden(true)
            }
            
            FooterOption
        }
        .task {
            Task {
                do {
                    try await storeKitManager.loadProducts()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    var CancelButton : some View {
        Button {
            HapticManager.shared.generateFeedback(for: .successLight)
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Cancel")
                .foregroundColor(.primary)
                .font(.subheadline)
        }
    }
    
    var HeaderText : some View {
        VStack() {
            Text("Try Words Premium")
                .font(.title)
                .bold()
            
        }
    }
    
    var Crown : some View {
        Image(systemName: "crown.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 60)
            .foregroundColor(.main)
    }
    
    var AdvantagesList : some View {
        VStack(alignment: .leading, spacing: 15){
            Advantage(text: "Enjoy the full experience")
            Advantage(text: "Learn words you didn't know")
            Advantage(text: "Expanded library of categories")
            Advantage(text: "Personalize your experience")
            Advantage(text: "No ads, no Watermarks")
        }
    }
    
    var FooterOption : some View {
        HStack(spacing: 60) {
            Button {
                
                HapticManager.shared.generateFeedback(for: .successLight)
                
                Task {
                    do {
                        try await AppStore.sync()
                    } catch {
                        print(error)
                    }
                }
            } label: {
                Text("Restore")
            }
            
            Link(destination: termsAndConditionsURL) {
                Text("Terms & Conditions")
            }
            .onTapGesture {
                HapticManager.shared.generateFeedback(for: .successLight)
            }
            .font(.caption2)
            .foregroundColor(.gray)

        }
        .font(.caption2)
        .foregroundColor(.gray)
    }
    
}
struct PremiumView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumView()
            .environmentObject(StoreKitManager())
    }
}

struct Advantage : View {
    
    let text : String
    
    var body : some View {
        HStack{
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.black, Color.main)
            Text(text)
        }
    }
}

