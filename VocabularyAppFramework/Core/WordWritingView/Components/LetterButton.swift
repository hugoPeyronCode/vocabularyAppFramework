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
      Text(String(item.letter).lowercased())
        .font(.custom(fontString, size: 40))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(isValidated ? .clear : isIncorrect  ? .red : fontColor)
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
