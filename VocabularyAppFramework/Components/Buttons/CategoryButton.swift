//
//  CategoryButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct CategoryButton: View {
    
    let text: String
    let icon: String
    let action: () -> Void
    
    // Compute the image name based on the text (category name)
    var imageName: String {
        return text.lowercased()
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(y: -20)
                
                VStack {
                    Spacer()
                    HStack {
                        Text(text)
                        Spacer()
                        Image(systemName: icon)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .offset(y: 10)
                    .padding()
                    .background()
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // This ensures all buttons have the same size
            .background(Color(.systemBackground))  // Adding a background to make the RoundedRectangle visible
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 2)
            .padding(9)
        }
    }
}

struct CategoryButton_Previews: PreviewProvider {
    static var previews: some View {
        CategoryButton(text: "society", icon: "checkmark", action: {})
    }
}