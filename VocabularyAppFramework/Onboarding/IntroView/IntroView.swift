//
//  IntroView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 30/10/2023.
//

import SwiftUI

struct IntroView: View {
    
    @ObservedObject var vm : OnboardingView.TabViewModel
    
    var body: some View {
        ZStack {
            VStack {
                
                Spacer()
                
                BackgroundImageView(imageName: "Onboarding1")
                
                Spacer()
                
                MiddleText
                
                Spacer()
                
                MoveToNextPageButton(isActive: .constant(true), action: vm.moveToNextPage)
            }
        }
    }
    
    
    var MiddleText : some View {
        VStack {
            
//           Text("Enhance Your Lexical Repertoire.")
            
            Text("Expand Your VOCABULARY")
                .font(.title)
                .bold()
            
//            Text("Cultivating a routine of acquiring new lexemes will significantly advance one's articulation and augment one's capacity for knowledge acquisition.")
            
            Text("Making a habit of learning new words will go a long way toward becoming more articulate and increase your learning capacity.")
                .padding()
            
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
        .foregroundStyle(.main)
        .shadow(color: .gray.opacity(0.3), radius: 10)
    }
}

#Preview {
    IntroView(vm: OnboardingView.TabViewModel())
}


