//
//  OnboardingBackgroundImageView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 30/10/2023.
//

import SwiftUI

struct BackgroundImageView: View {
    
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxHeight: 200)
    }
}

#Preview {
    BackgroundImageView(imageName: "Onboarding1")
}
