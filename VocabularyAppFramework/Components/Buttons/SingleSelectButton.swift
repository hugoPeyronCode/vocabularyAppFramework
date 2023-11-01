//
//  SingleSelectButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 31/10/2023.
//

import SwiftUI

struct SingleSelectButton: View {
    let content: String
    @Binding var selectedItems : [String]
    
    var body: some View {
        Button {
            if !selectedItems.isEmpty {
                    selectedItems.removeAll()
                }
                selectedItems.append(content)
            
        } label: {
            RoundedRectangle(cornerRadius: 50)
                .stroke(lineWidth: 1.0)
                .foregroundStyle(isSelected() ? .main : .gray)
                .overlay {
                    Text(content)
                        .foregroundStyle(isSelected() ? .main : .gray)
                        .fontWeight(isSelected() ? .bold : .regular)
                }
                .frame(maxWidth: .infinity, maxHeight: 50)
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
    SingleSelectButton(content: "Example", selectedItems: .constant(["Bob"]))
}
