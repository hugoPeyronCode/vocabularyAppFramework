//
//  SurveyButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 31/10/2023.
//

import SwiftUI

struct MultiSelectButton : View {
    let content: String
    @State private var isSelected : Bool = false
    @Binding var selectedItems : [String]
    
    var body: some View {
        Button {
            isSelected.toggle()
            if isSelected == true {
                selectedItems.append(content)
            } else {
                selectedItems.removeLast()
            }
            
        } label: {
            RoundedRectangle(cornerRadius: 50)
                .stroke(lineWidth: 1.0)
                .foregroundStyle(isSelected ? .main : .gray)
                .overlay {
                    Text(content)
                        .foregroundStyle(isSelected ? .main : .gray)
                        .fontWeight(isSelected ? .bold : .regular)
                }
                .frame(maxWidth: .infinity, maxHeight: 50)
                .padding(.horizontal)
        }
    }
}

#Preview {
    MultiSelectButton(content: "Example", selectedItems: .constant(["Joe"]))
}
