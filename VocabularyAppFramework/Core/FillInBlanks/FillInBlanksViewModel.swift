//
//  FillInBlanksViewModel.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 10/12/2024.
//

import SwiftUI

class FillInBlanksViewModel: ObservableObject {

  let word: Word
  @Published var fontColor: Color
  @Published var fontString: String
  @Published var selectedLetters: [Character] = []
  @Published var availableLetters: [(id: UUID, letter: Character)] = []
  @Published var validatedLetterIds = Set<UUID>()
  @Published var incorrectLetterId: UUID?
  @Published var isComplete = false
  @Published var currentHighlightIndex: Int = 0

  private var maskedIndices: [Int] = []
  private var correctLetters: [Character] = []

  init(word: Word, fontColor: Color, fontString: String) {
    self.word = word
    self.fontColor = fontColor
    self.fontString = fontString
    setupGame()
  }

  private func setupGame() {
    let letters = Array(word.Headword)
    correctLetters = letters

    // Safety check - need at least 3 letters
    guard letters.count >= 3 else {
      maskedIndices = []
      availableLetters = []
      return
    }

    // Get all possible indices (excluding first and last)
    let middleIndices = Array(1...(letters.count - 2))

    // Calculate number of letters to mask (60% of middle letters)
    let numberOfLettersToMask = max(
      2,  // minimum 2 letters
      min(
        middleIndices.count,  // don't exceed available letters
        Int(ceil(Double(middleIndices.count) * 0.6))  // 60% of middle letters
      )
    )

    // Only proceed if we have enough letters to mask
    guard !middleIndices.isEmpty && numberOfLettersToMask > 0 else {
      maskedIndices = []
      availableLetters = []
      return
    }

    // Randomly select indices to mask
    maskedIndices = Array(middleIndices.shuffled().prefix(numberOfLettersToMask))
    maskedIndices.sort() // Keep indices in order

    // Create available letters from masked positions
    let lettersToShow = maskedIndices.map { letters[$0] }
    availableLetters = lettersToShow.shuffled().map { (UUID(), $0) }
  }

  func handleLetterTap(_ item: (id: UUID, letter: Character)) {
    let currentIndex = selectedLetters.count

    if currentIndex < maskedIndices.count {
      let correctLetter = correctLetters[maskedIndices[currentIndex]]

      if item.letter == correctLetter {
        selectedLetters.append(item.letter)
        validatedLetterIds.insert(item.id)

        if selectedLetters.count == maskedIndices.count {
          // Add a small delay before completing to allow for the last green animation
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isComplete = true
          }
        } else {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentHighlightIndex += 1
          }
        }
      } else {
        incorrectLetterId = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          self.incorrectLetterId = nil
        }
      }
    }
  }

  func isLetterMasked(at index: Int) -> Bool {
    maskedIndices.contains(index)
  }

  func getMaskedLetterIndex(at index: Int) -> Int? {
    maskedIndices.firstIndex(of: index)
  }
}
