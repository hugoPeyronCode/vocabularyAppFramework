//
//  SingleSelectButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 31/10/2023.
//

import SwiftUI

struct SingleSelectButton: View {
    let content: String
    let whenSelectedColor : Color = .main
    let defaultColor : Color
    let fontString : String
    @Binding var selectedItems : [String]
    let action : () -> Void
    
        var body: some View {
        Button {
            if !selectedItems.isEmpty {
                    selectedItems.removeAll()
                }
                selectedItems.append(content)
            HapticManager.shared.generateFeedback(for: .successLight)
            action()
        } label: {
                RoundedRectangle(cornerRadius: 50)
                    .stroke(lineWidth: 1.0)
                    .foregroundStyle(isSelected() ? whenSelectedColor : defaultColor)
                    .overlay {
                        Text(content)
                            .foregroundStyle(isSelected() ? whenSelectedColor : defaultColor)
                            .font(.custom(fontString, size: 20))
                            .fontWeight(isSelected() ? .bold : .regular)
                    }
                    .frame(width: 350, height: 50)
                    .padding(.horizontal)
        }
    }
    
    func isSelected() -> Bool {
        if selectedItems.contains(content) {
            return true
        } else {
            return false
        }
    }
}

#Preview {
    SingleSelectButton(content: "Example", defaultColor: .black, fontString: "default", selectedItems: .constant(["Bob"]), action: {})
}
