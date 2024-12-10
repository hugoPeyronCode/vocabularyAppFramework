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

  func generateOptions(from word: String) -> [String] {
    guard word.count >= 2 else { return [word] } // Safety check for very short words

    let letters = Array(word)
    var options: [String] = []

    // Generate the correct answer as an anagram
    if letters.count >= 2 {
      shuffledCorrectWord = String(letters.shuffled())
      if shuffledCorrectWord == word {
        // If we got the same word, swap two letters
        var mutableLetters = Array(shuffledCorrectWord)
        if mutableLetters.count >= 2 {
          mutableLetters.swapAt(0, 1)
          shuffledCorrectWord = String(mutableLetters)
        }
      }
      options.append(shuffledCorrectWord)
    }

    // Generate wrong answers
    let alphabet = Array("abcdefghijklmnopqrstuvwxyz")

    while options.count < 4 {
      var wrongLetters = letters

      // Modify 1-2 letters to create similar but incorrect options
      let numberOfChanges = min(Int.random(in: 1...2), wrongLetters.count)

      for _ in 0..<numberOfChanges {
        if let indexToChange = wrongLetters.indices.randomElement(),
           let newLetter = alphabet.randomElement() {
          wrongLetters[indexToChange] = newLetter
        }
      }

      let wrongOption = String(wrongLetters.shuffled())
      if !options.contains(wrongOption) && wrongOption != word {
        options.append(wrongOption)
      }
    }

    return options.shuffled()
  }

  var body: some View {
    VStack(spacing: 30) {
      Text(word.Headword)
        .font(.custom(fontString, size: 40))
        .bold()

      if !options.isEmpty {
        VStack(spacing: 15) {
          ForEach(options, id: \.self) { option in
            Button(action: {
              selectedOption = option
            }) {
              Text(option)
                .font(.custom(fontString, size: 30))
                .padding()
                .frame(maxWidth: .infinity)
                .background(backgroundColor(for: option))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
          }
        }
        .padding()
      }

      if let selected = selectedOption {
        Text(selected == shuffledCorrectWord ? "Correct!" : "Try again")
          .foregroundColor(selected == shuffledCorrectWord ? .green : .red)
          .font(.custom(fontString, size: 20))
      }

      if selectedOption == shuffledCorrectWord {
        VStack(spacing: 10) {
          Text(word.Definition)
            .font(.custom(fontString, size: 19))
          Text(word.Context_sentence)
            .font(.custom(fontString, size: 15))
        }
        .multilineTextAlignment(.center)
        .padding()
      }
    }
    .foregroundColor(fontColor)
    .onAppear {
      options = generateOptions(from: word.Headword)
    }
  }

  private func backgroundColor(for option: String) -> Color {
    guard let selected = selectedOption else {
      return fontColor.opacity(0.1)
    }
    return option == selected
    ? (option == shuffledCorrectWord ? .green.opacity(0.2) : .red.opacity(0.2))
    : fontColor.opacity(0.1)
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
