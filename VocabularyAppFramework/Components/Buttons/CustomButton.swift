//
//  CustomButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct CustomButton: View {
    
    let text : String
    let image : String
    let action : () -> Void
    
    var body: some View {
        Button {
            action()
            HapticManager.shared.generateFeedback(for: .successLight)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: image)
                    .fontWeight(.thin)
                Text(text)
                    .fontWeight(.light)
                    .font(.caption)
            }
            .frame(height: 25)
            .padding()
            .foregroundColor(.primary)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: .black.opacity(0.3), radius: 3)
        }
    }
}

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomButton(text: "Category", image: "crown", action: {})
    }
}
