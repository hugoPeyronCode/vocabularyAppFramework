//
//  WordWritingViewModel.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 09/12/2024.
//

import SwiftUI

@Observable
class WordWritingViewModel {
  let word: Word
  let fontColor: Color
  let fontString: String

  var selectedLetters: [Character] = []
  var availableLetters: [(id: UUID, letter: Character)] = []
  var isComplete: Bool = false
  var validatedLetterIds: Set<UUID> = []
  var incorrectLetterId: UUID?

  init(word: Word, fontColor: Color, fontString: String) {
    self.word = word
    self.fontColor = fontColor
    self.fontString = fontString
    self.availableLetters = Array(word.Headword.uppercased()).map { (UUID(), $0) }.shuffled()
  }

  func handleLetterTap(_ item: (id: UUID, letter: Character)) {
    let targetLetter = Array(word.Headword.uppercased())[selectedLetters.count]
    if item.letter.uppercased() == String(targetLetter).uppercased() {
      selectedLetters.append(item.letter)
      validatedLetterIds.insert(item.id)
      if selectedLetters.count == word.Headword.count {
        isComplete = true
      }
    } else {
      incorrectLetterId = item.id
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.incorrectLetterId = nil
      }
    }
  }
}
