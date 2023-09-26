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
        } label: {
            HStack(spacing: 3) {
                Image(systemName: image)
                    .fontWeight(.thin)
                    .frame(height: 15)
                Text(text)
                    .fontWeight(.light)
                    .font(.caption)
            }
            .foregroundColor(.primary)
            .padding()
            .background(.thinMaterial)
            .cornerRadius(150)
            .shadow(color: .gray.opacity(0.3), radius: 3)
        }
    }
}

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomButton(text: "Category", image: "crown", action: {})
    }
}
