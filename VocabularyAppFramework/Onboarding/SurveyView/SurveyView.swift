//
//  SuveryView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 31/10/2023.
//

import SwiftUI

struct SurveyView: View {
    
    @EnvironmentObject var themesManager: ThemesManager
    var isMain : Bool { themesManager.currentTheme.backgroundImage == "Main" }
    
    let options = ["Enhance my lexicon", "Get ready for a test", "Improve my job prospects", "Enjoying learning new words", "Other"]
    
    @State var selectedItems : [String] = []
    
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                
                Spacer()
                
                OnboardingBackgroundImageView(imageName: "Onboarding1")

                Spacer()
                
                MiddleText
                
                ForEach(options, id: \.self) { item in
                    MultiSelectButton(content: item, selectedItems: $selectedItems)
                }
                
                Spacer()
                
                FooterText
                
                Spacer()
            }
            .background(
                ZStack{
                    Image(themesManager.currentTheme.backgroundImage).opacity(isMain ? 0.2 : 1)
                    if themesManager.currentTheme.needContrast == true {
                        Color(.black).opacity(0.2)
                    }
                }
            )
        }
    }
    
    
    var MiddleText : some View {
        VStack {
            
            Text("Tell us why you're here?")
                .font(.title)
                .bold()
        }
        .fontDesign(.serif)
        .padding()
        .multilineTextAlignment(.center)
    }
    

    
    var FooterText : some View {
        HStack {
            Image(systemName: "hand.draw")
            Text("swipe right")
        }
        .fontDesign(.rounded)
        .bold()
        .foregroundStyle(selectedItems.isEmpty ? .clear : .main)
        .shadow(color: .gray.opacity(0.3), radius: 10)
    }
}

#Preview {
    SurveyView()
        .environmentObject(ThemesManager())
}

