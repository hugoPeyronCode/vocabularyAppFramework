//
//  LetterButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 09/12/2024.
//

import SwiftUI

struct LetterButtonView: View {
  let item: (id: UUID, letter: Character)
  let fontString: String
  let fontColor: Color
  let isValidated: Bool
  let isIncorrect: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      Text(String(item.letter).uppercased())
        .font(.custom(fontString, size: 40))
        .frame(width: 50, height: 50)
        .background(fontColor.opacity(0.09))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(
              isValidated ? .main :
                isIncorrect ? Color.red :
                Color.black,
              lineWidth: 2
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(isValidated ? .main : fontColor)
    }
    .sensoryFeedback(.success, trigger: isValidated)
    .sensoryFeedback(.error, trigger: isIncorrect)
    .disabled(isValidated)
    .animation(.bouncy, value: isValidated)
  }
}

#Preview("LetterButtonView") {
    LetterButtonView(
      item: (UUID(), "A"),
      fontString: "Georgia",
      fontColor: .black,
      isValidated: false,
      isIncorrect: false,
      onTap: {}
    )
}
