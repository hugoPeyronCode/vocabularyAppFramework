//
//  PremiumView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.

// hugosandboxtester@gmail.com
// @@BXa?oe?C3M7Cmk

// Privacy policy link :https://www.notion.so/APPLICATION-TERMS-AND-CONDITIONS-OF-USE-AND-PRIVACY-POLICY-431520373299481a97353288b54489f5?pvs=4


// On this view I need to fix the issue of the background always being white due to the presence of the navigation stack.

import SwiftUI
import StoreKit

struct PremiumView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var storeKitManager : StoreKitManager
    
    @State private var showCancelButton = false
    
    @State private var selectedProduct : Product?
    
    let termsAndConditionsURL = URL(string: "https://www.notion.so/APPLICATION-TERMS-AND-CONDITIONS-OF-USE-AND-PRIVACY-POLICY-431520373299481a97353288b54489f5?pvs=4")!
    
    var body: some View {
        ZStack {
            
            if storeKitManager.isLoading { LoadingSymbol }
            
            VStack {
                HStack {
                    CancelButton
                        .padding()
                    Spacer()
                }
                Spacer()
            }
            
            VStack {
                
                HeaderText
                
                Spacer()
                
                AdvantagesList
                
                Spacer()
                
                ProductsSelection
                
                Spacer()
                
                ContinueButton
                
                FooterOption
            }
        }
        .navigationBarBackButtonHidden(true)
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
    
    var LoadingSymbol : some View {
        ProgressView() // Show loading symbol when isLoading is true
            .progressViewStyle(CircularProgressViewStyle())
            .padding()
            .background(.thickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 150))
            .tint(.main)
            .scaleEffect(2)
    }
    
    var CancelButton : some View {
        Button {
            HapticManager.shared.generateFeedback(for: .successLight)
            presentationMode.wrappedValue.dismiss()
        } label: {
            if showCancelButton {
                Image(systemName: "xmark")
                    .foregroundStyle(.gray.opacity(0.4))
                    .font(.subheadline)
            }
        }
        .onAppear {
            if storeKitManager.isLoading == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    showCancelButton = true
                }
            }
        }
    }
    
    var HeaderText : some View {
        VStack(spacing: 10) {
            Text("Try Words Premium")
                .font(.title)
                .bold()
            
            Text("Unlock everything")
                .font(.title2)
                .bold()
            
        }
        .padding()
    }
    
    var ProductsSelection : some View {
        HStack{
            ForEach(storeKitManager.products) { product in
                Button {
                    selectedProduct = product
                } label: {
                    VStack(spacing: 40) {
                        Text(product.displayName.capitalized)
                        Text("\(product.displayPrice)")
                            .bold()
                        
                        switch product.displayName {
                        case  "Yearly": Text("per year").font(.caption2)
                        case "weekly": Text("per week").font(.caption2)
                        case "Lifetime": Text("one time").font(.caption2)
                        default : Text("")
                        }
                    }
                    .font(.subheadline)
                    .padding()
                    .frame(width: 100)
                    .foregroundStyle(.black)
                    .background(selectedProduct == product ? .main : .main.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.main, lineWidth: 1)
                    )
                }
                .onAppear{
                    if product.displayName == "weekly" {
                        selectedProduct = product
                    }
                }
            }
        }
    }
    
    var Crown : some View {
        Image("Premium")
            .resizable()
            .scaledToFit()
            .frame(width: 300, height: 300)
    }
    
    var AdvantagesList : some View {
        VStack(alignment: .leading, spacing: 15){
            Advantage(text: "Enjoy one year of full experience")
            Advantage(text: "Expanded library of categories")
            Advantage(text: "Personalize your experience")
            Advantage(text: "No ads, no Watermarks")
        }
    }
    
    var ContinueButton : some View {
        CustomButtonMarked(text: "Continue", isActive: true, action: {
            HapticManager.shared.generateFeedback(for: .successLight)
            if let product = selectedProduct {
                Task {
                    do {
                        try await storeKitManager.purchase(product)
                    } catch {
                        print(error)
                    }
                }
            }
        })
        .padding()
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

