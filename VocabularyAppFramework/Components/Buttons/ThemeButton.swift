//
//  ThemeButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI



struct ThemeButton: View {
    let theme : Theme
    let action : (Theme) -> Void
    
    var body: some View {
        Button {
            action(theme)
        } label: {
            ZStack {
                Image(theme.backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 150)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                LockIcon
            }
            .frame(width: 100)
        }
    }
        
    var LockIcon : some View {
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
    
    static let theme : Theme = Theme(backgroundImage: "BlackTexture1", font: .body, fontColor: .white)
    
    static var previews: some View {
        ThemeButton(theme: theme, action: {_ in })
    }
}
