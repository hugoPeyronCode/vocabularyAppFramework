//
//  SuveryView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 31/10/2023.
//

import SwiftUI

struct SurveyView: View {
    
    @ObservedObject var vm : OnboardingView.TabViewModel
    
    let options = ["Enhance my lexicon", "Get ready for a test", "Improve my job prospects", "Enjoying learning new words", "Other"]
    
    @State var selectedItems : [String] = []
    
    @State var isActive : Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                
                Spacer()
                
                BackgroundImageView(imageName: "OnboardingMouth")
                    .scaleEffect(0.8)

                Spacer()
                
                MiddleText
                
                ForEach(options, id: \.self) { item in
                    MultiSelectButton(content: item, selectedItems: $selectedItems) { isActive = true}
                }
                
                Spacer()
                
                MoveToNextPageButton(isActive: $isActive, action: vm.moveToNextPage)
            }
        }
    }
    
    
    var MiddleText : some View {
        VStack {
            
            Text("Tell us why you're here")
                .font(.title)
                .bold()
        }
        .fontDesign(.serif)
        .padding()
        .multilineTextAlignment(.center)
    }
    

    
//    var FooterText : some View {
//        HStack {
//            Image(systemName: "hand.draw")
//            Text("swipe right")
//        }
//        .fontDesign(.rounded)
//        .bold()
//        .foregroundStyle(selectedItems.isEmpty ? .clear : .main)
//        .shadow(color: .gray.opacity(0.3), radius: 10)
//    }
}

#Preview {
    SurveyView(vm: OnboardingView.TabViewModel())
}

