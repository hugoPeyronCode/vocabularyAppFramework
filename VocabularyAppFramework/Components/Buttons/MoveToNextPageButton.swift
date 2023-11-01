//
//  MoveToNextPageButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 01/11/2023.
//

import SwiftUI

struct MoveToNextPageButton : View {
    
    var content: String
    var icon : String
    
    var defaultColor: Color
    var fontString: String
    
    @Binding var isActive : Bool
    @State var action : () -> Void
    
    // Default initializer
    init(isActive: Binding<Bool>, action: @escaping () -> Void) {
        self.content = "Continue"
        self.icon = "hand.tap"
        self.defaultColor = .gray
        self.fontString = ".rounded"
        _isActive = isActive
        self.action = action
    }
    
    // Custom initializer that allows changing content and icon
    init(content: String, icon: String , defaultColor: Color, fontString: String, isActive: Binding<Bool>, action: @escaping () -> Void) {
        self.content = content
        self.icon = icon
        self.defaultColor = defaultColor
        self.fontString = fontString
        _isActive = isActive
        self.action = action
    }
    
    var body: some View{
        Button{
            action()
            HapticManager.shared.generateFeedback(for: .successLight)
        } label: {
            HStack {
                Text(content)
                    .font(.custom(fontString, size: 19))
                Image(systemName: icon)
            }
            .padding()
            .background(isActive ? .main.opacity(0.1) : .gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .bold()
            .foregroundStyle(isActive ? .main : defaultColor)
        }
        .disabled(!isActive)
    }
}

#Preview {
    MoveToNextPageButton(isActive: .constant(true), action: {})
}
