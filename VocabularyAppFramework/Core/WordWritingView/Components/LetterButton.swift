//
//  LetterButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 09/12/2024.
//

import SwiftUI

struct LetterButtonView: View {
    let item: (id: UUID, letter: Character)
    let geometry: GeometryProxy
    let fontString: String
    let fontColor: Color
    let isValidated: Bool
    let isIncorrect: Bool 
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(String(item.letter).uppercased())
                .font(.custom(fontString, size: min(geometry.size.width / 15, 24)).bold())
                .frame(width: min(geometry.size.width / 8, 50), height: min(geometry.size.width / 8, 50))
                .background(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isValidated ? Color.green :
                            isIncorrect ? Color.red :
                            Color.clear,
                            lineWidth: 2
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(isValidated ? .green : fontColor)
        }
        .sensoryFeedback(.success, trigger: isValidated)
        .sensoryFeedback(.error, trigger: isIncorrect)
        .disabled(isValidated)
        .animation(.bouncy, value: isValidated)
    }
}

#Preview("LetterButtonView") {
    GeometryReader { geometry in
        LetterButtonView(
            item: (UUID(), "A"),
            geometry: geometry,
            fontString: "Georgia",
            fontColor: .black,
            isValidated: false,
            isIncorrect: false,
            onTap: {}
        )
    }
    .frame(width: 100, height: 100)
}
