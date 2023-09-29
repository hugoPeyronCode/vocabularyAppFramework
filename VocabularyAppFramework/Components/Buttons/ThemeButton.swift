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
    
    @EnvironmentObject var themesManager: ThemesManager
    
    var isSelected : Bool { themesManager.currentTheme == theme }

    var body: some View {
        Button {
            action(theme)
        } label: {
            ZStack {
                Image(theme.backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .opacity(theme.backgroundImage == "Main" ? 0.3 : 1)
                    .frame(width: 90, height: 150)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color : .main, radius: isSelected ? 3 : 0)
                    .shadow(color : .main, radius: isSelected ? 3 : 0)
                
                Text("ABC")
                    .font(.custom(theme.font, size: 30))
                    .foregroundColor(theme.fontColor)
                
                CheckIcon
                
//                LockIcon
                
                
            }
            .frame(width: 100, height: 150)
        }
    }
    
    var CheckIcon : some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: isSelected ? "checkmark" : "")
                    .foregroundColor(.white)
                    .padding(7)
                    .shadow(radius: 1)
                    .shadow(radius: 1)
            }
            
            Spacer()
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
    
    static let theme : Theme = Theme(backgroundImage: "BlackTexture1", font: "Chalkduster", fontColor: .white)
    
    static var previews: some View {
        ThemeButton(theme: theme, action: {_ in })
            .environmentObject(ThemesManager())
    }
}
