//
//  PremiumView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct PremiumView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @StateObject private var iapManager = IAPManager.shared
    
    var priceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = iapManager.products.first?.priceLocale
        return formatter.string(from: iapManager.products.first?.price ?? 0) ?? "error"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                
                HeaderText
                
                IAPInfos
                
                Crown
                
                Text("Unlock everything")
                    .font(.title2)
                    .bold()
                
                AdvantagesList
                
                Spacer()
                
                
                Text(priceString)

                CustomButtonMarked(text: "Continue", action: {
                    if let product = iapManager.products.first {
                        iapManager.purchase(product: product)
                    }
                })
                    .padding(.horizontal)
                
                FooterOption
                
            }
            .navigationBarItems(leading: CancelButton)
            .navigationBarBackButtonHidden(true)
        }
    }
    

    var IAPInfos : some View {
        VStack{
            Text(iapManager.products.first?.localizedTitle ?? "error")
            Text(iapManager.products.first?.localizedDescription ?? "error")
            Text(iapManager.products.first?.price.stringValue ?? "error")
        }
    }
    
    var CancelButton : some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Cancel")
                .foregroundColor(.primary)
                .font(.subheadline)
        }
    }
    
    var HeaderText : some View {
        VStack() {
            Text("Try Vocabulary Premium")
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
            Advantage(text: "Reminders to help you learn")
            Advantage(text: "No ads \nno Watermarks")
            Advantage(text: "Only 1.66€/month, billed annually")
        }
    }
    
    var FooterOption : some View {
        HStack(spacing: 60) {
            Button {
                //
            } label: {
                Text("Restore")
            }
            
            Button {
                //
            } label: {
                Text("Terms & Conditions")
            }
            
            Button {
                //
            } label: {
                Text("Other")
            }
        }
        .font(.caption2)
        .foregroundColor(.gray)
    }
}

struct PremiumView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumView()
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

