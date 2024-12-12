//
//  AskForRatingView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 31/10/2023.
//

import SwiftUI
import StoreKit

struct AskForRatingView: View {
    
    @ObservedObject var vm : OnboardingView.TabViewModel
    
    @State private var selectedItems : [String] = []
    
    @State var imageName : String = "star"
    
    @State var isActive : Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                
                Spacer()
                
                BackgroundImageView(imageName: "OnboardingHeart")
                    .scaleEffect(0.8)
                
                Spacer()
                
                MiddleText
                
                Spacer()
                
                HStack{
                    ForEach(0 ..< 5) { item in
                        Image(systemName: imageName)
                            .font(.title)
                            .foregroundStyle(.main)
                            .onTapGesture {
                                withAnimation(.smooth) {
                                    imageName = "star.fill"
                                    isActive = true
                                }
                                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                                    SKStoreReviewController.requestReview(in: scene)
                                }
                            }
                    }
                }
                .sensoryFeedback(.impact, trigger: isActive)
                .padding()
                .background(.main.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 50))
                
                HStack {
                    Image(systemName: "hand.tap")
                    Text("Click me")
                        .font(.caption)
                }
                .foregroundStyle(.main)
                
                Spacer()
                
                MoveToNextPageButton(isActive: $isActive, action: vm.moveToNextPage)
            }

        }
    }
    
    var MiddleText : some View {
        VStack {
            Text("Might you lend us your support?")
                .font(.title)
                .bold()
                .frame(maxHeight: 90)
            
            Text("Bestowing upon us a 5-star rating provides an immense uplift. Merely a moment of your time equates to a gracious gift you extend to us.")
        }
        .fontDesign(.serif)
        .padding()
        .multilineTextAlignment(.center)
    }

}

#Preview {
    AskForRatingView(vm: OnboardingView.TabViewModel())
}

