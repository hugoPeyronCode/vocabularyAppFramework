//
//  UserLevelView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 31/10/2023.
//

import SwiftUI

struct UserLevelView: View {
    
    @ObservedObject var vm : OnboardingView.TabViewModel
    
    let options = ["Beginner", "Intermediate", "Advanced"]
    
    @State var selectedItems : [String] = []
    
    @State var isActive : Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                
                Spacer()
                
                BackgroundImageView(imageName: "OnboardingPodium")
                    .scaleEffect(0.8)

                Spacer()
                
                MiddleText
                
                ForEach(options, id: \.self) { item in
                    SingleSelectButton(content: item, defaultColor: .black, fontString: ".rounded", selectedItems: $selectedItems) {
                        print("Button tapped!")
                        isActive = true
                    }
                }
                
                Spacer()
                
                MoveToNextPageButton(isActive: $isActive, action: vm.moveToNextPage)
            }
        }
    }
    
    var MiddleText : some View {
        VStack {
            Text("What's your vocabulary level?")
                .font(.title)
                .bold()
                .frame(maxHeight: 90)
        }
        .fontDesign(.serif)
        .padding()
        .multilineTextAlignment(.center)
    }
}

#Preview {
    UserLevelView(vm: OnboardingView.TabViewModel())
}
