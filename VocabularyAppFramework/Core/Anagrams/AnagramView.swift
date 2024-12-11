//
//  AnagramView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 10/12/2024.
//

import SwiftUI

struct AnagramView: View {
  let word: Word
  let fontColor: Color
  let fontString: String

  @State private var options: [String] = []
  @State private var selectedOption: String?
  @State private var shuffledCorrectWord: String = ""

  var body: some View {
    VStack(spacing: 30) {
      Text(word.Headword)
        .font(.custom(fontString, size: 45))

      if !options.isEmpty {
        VStack(spacing: 15) {
          ForEach(options, id: \.self) { option in
            Button(action: {
              selectedOption = option
            }) {
              Text(option)
                .font(.custom(fontString, size: 25))
                .padding()
                .frame(maxWidth: .infinity)
                .background(backgroundColor(for: option))
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
          }
        }
        .padding()
      }

        VStack(spacing: 10) {
          Text(word.Definition)
            .font(.custom(fontString, size: 19))
          Text(word.Context_sentence)
            .font(.custom(fontString, size: 15))
        }
        .opacity(selectedOption == shuffledCorrectWord ? 1 : 0)
        .multilineTextAlignment(.center)
        .padding()
    }
    .foregroundColor(fontColor)
    .onAppear {
      options = generateOptions(from: word.Headword)
    }
  }

  private func backgroundColor(for option: String) -> Color {
    guard let selected = selectedOption else {
      return fontColor.opacity(0.03)
    }
    return option == selected
    ? (option == shuffledCorrectWord ? .green.opacity(0.2) : .red.opacity(0.2))
    : fontColor.opacity(0.03)
  }
}


extension AnagramView {
  func generateOptions(from word: String) -> [String] {
      // Need at least 3 letters for meaningful anagrams
      guard word.count >= 3 else {
          shuffledCorrectWord = word
          return [word]
      }

      let letters = Array(word)
      var options: [String] = []

      // Generate correct anagram (must be different from original word)
      var attempts = 0
      repeat {
          shuffledCorrectWord = String(letters.shuffled())
          attempts += 1

          // If we can't get a different shuffle after 5 attempts, force changes
          if attempts >= 5 && shuffledCorrectWord == word {
              var mutableLetters = Array(word)
              // Swap first two letters
              mutableLetters.swapAt(0, min(1, mutableLetters.count - 1))
              // If possible, also swap another pair
              if mutableLetters.count >= 3 {
                  mutableLetters.swapAt(1, 2)
              }
              shuffledCorrectWord = String(mutableLetters)
              break
          }
      } while shuffledCorrectWord == word && attempts < 5

      options.append(shuffledCorrectWord)

      // Generate wrong answers
      let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
      var attempts2 = 0

      while options.count < 4 && attempts2 < 20 {  // Add maximum attempts
          attempts2 += 1
          var wrongLetters = Array(word)

          // Change at least 2 letters or 60% of the word
          let targetChanges = max(2, Int(ceil(Double(wrongLetters.count) * 0.6)))
          var changedCount = 0

          // Try to make changes
          for _ in 0..<targetChanges {
              if let indexToChange = wrongLetters.indices.randomElement(),
                 let newLetter = alphabet.randomElement(),
                 newLetter != wrongLetters[indexToChange] {
                  wrongLetters[indexToChange] = newLetter
                  changedCount += 1
              }
          }

          // Only add if we made enough changes
          if changedCount >= 2 {
              let wrongOption = String(wrongLetters.shuffled())
              if !options.contains(wrongOption) && wrongOption != word {
                  options.append(wrongOption)
              }
          }
      }

      // If we couldn't generate enough options, fill with simple modifications
      while options.count < 4 {
          var filler = Array(word)
          if let index = filler.indices.randomElement() {
              filler[index] = "x"
              let fillerOption = String(filler)
              if !options.contains(fillerOption) {
                  options.append(fillerOption)
              }
          }
      }

      return options.shuffled()
  }
}

#Preview {
  AnagramView(
    word: Word(
      Rank: "1",
      List: "test",
      Headword: "myeloma",  // Using a word long enough for anagrams
      Definition: "A malignant tumor of bone marrow plasma cells.",
      Context_sentence: "The patient was diagnosed with multiple myeloma.",
      Synonyms: "plasma cell myeloma",
      Antonyms: "",
      Topic: "medical"
    ),
    fontColor: .black,
    fontString: "Georgia"
  )
}
