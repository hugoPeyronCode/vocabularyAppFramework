//
//  ThemeButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct ThemeButton: View {
    let mainImage: String
    let action : () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Image(mainImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 150)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Icon
            }
            .frame(width: 100)
        }
    }
    
    
    var Icon : some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: "lock")
                    .foregroundColor(.white)
                    .bold()
                    .padding(7)
                    .shadow(radius: 1)
                    .shadow(radius: 1)

            }
            
            Spacer()
        }
    }
}

struct ThemeButton_Previews: PreviewProvider {
    static var previews: some View {
        ThemeButton(mainImage: "All", action: {})
    }
}
