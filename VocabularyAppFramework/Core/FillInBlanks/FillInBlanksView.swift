//
//  FillInBlanksView.swift
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

    // Calculate number of letters to mask (40% of word length)
    let numberOfLettersToMask = max(Int(Double(letters.count - 2) * 0.4), 1)

    // Get all possible indices (excluding first and last)
    let middleIndices = Array(1...(letters.count - 2))

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

struct FillInBlanksView: View {
  @StateObject private var vm: FillInBlanksViewModel
  @EnvironmentObject var themesManager: ThemesManager

  init(word: Word, fontColor: Color, fontString: String) {
    _vm = StateObject(wrappedValue: FillInBlanksViewModel(
      word: word,
      fontColor: fontColor,
      fontString: fontString
    ))
  }

  private func updateViewModel() {
      vm.fontColor = themesManager.currentTheme.fontColor
      vm.fontString = themesManager.currentTheme.font
  }

  var body: some View {
    GeometryReader { geometry in
      VStack {
        Spacer()

        VStack(spacing: 90) {
          WordToComplete(geometry: geometry)
          WordContent
        }

        Spacer()

        LetterGrid(geometry: geometry)

        Spacer()
      }
      .padding()
      .foregroundColor(vm.fontColor)
      .shadow(radius: vm.fontColor == .white ? 1 : 0)
      .font(.custom(vm.fontString, size: 45))
    }
    .onChange(of: themesManager.currentTheme) { _, _ in
         updateViewModel()
     }
  }

  private func WordToComplete(geometry: GeometryProxy) -> some View {
    HStack(spacing: 8) {
      ForEach(Array(vm.word.Headword.enumerated()), id: \.offset) { index, letter in
        if vm.isLetterMasked(at: index) {
          if let maskedIndex = vm.getMaskedLetterIndex(at: index) {
            if maskedIndex < vm.selectedLetters.count {
              // Show the found letter with animation
              Text(String(vm.selectedLetters[maskedIndex]).uppercased())
                .font(.custom(vm.fontString, size: min(geometry.size.width / CGFloat(Double(vm.word.Headword.count) * 1.5), 46)))
                .bold()
                .foregroundStyle(vm.isComplete ? vm.fontColor : .green)
                .animation(.easeIn(duration: 1), value: vm.selectedLetters.count)
                .animation(.easeIn(duration: 1), value: vm.isComplete)
            } else {
              // Show underscore for unfound letters
              Text("_")
                .font(.custom(vm.fontString, size: min(geometry.size.width / CGFloat(Double(vm.word.Headword.count) * 1.5), 46)))
                .bold()
                .foregroundStyle(
                  maskedIndex == vm.currentHighlightIndex
                  ? .blue
                  : vm.fontColor.opacity(0.3)
                )
            }
          }
        } else {
          // Show unmasked letters
          Text(String(letter).uppercased())
            .font(.custom(vm.fontString, size: min(geometry.size.width / CGFloat(Double(vm.word.Headword.count) * 1.5), 46)))
            .bold()
            .foregroundStyle(vm.fontColor)
        }
      }
    }
    .animation(.easeInOut(duration: 1), value: vm.selectedLetters)
  }

  private var WordContent: some View {
    VStack(spacing: 20) {
      Text(vm.word.Definition)
        .font(.custom(vm.fontString, size: 19))

      Text("(\(vm.word.Context_sentence))")
        .frame(height: 50)
        .font(.custom(vm.fontString, size: 15))
    }
    .minimumScaleFactor(0.7)
    .lineLimit(nil)
    .multilineTextAlignment(.center)
    .foregroundColor(vm.fontColor)
    .shadow(radius: vm.fontColor == .white ? 1 : 0)
    .frame(height: 100)
  }

  private func LetterGrid(geometry: GeometryProxy) -> some View {
    let columns = [
      GridItem(.adaptive(minimum: min(geometry.size.width / 8, 60), maximum: 60), spacing: 8)
    ]

    return VStack {
      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(vm.availableLetters, id: \.id) { item in
          LetterButtonView(
            item: item,
            geometry: geometry,
            fontString: vm.fontString,
            fontColor: vm.fontColor,
            isValidated: vm.validatedLetterIds.contains(item.id),
            isIncorrect: vm.incorrectLetterId == item.id
          ) {
            vm.handleLetterTap(item)
          }
        }
      }
      .padding(.horizontal)
    }
  }
}

#Preview {
  FillInBlanksView(
    word: Word(
      Rank: "1",
      List: "test",
      Headword: "myeloma",
      Definition: "A malignant tumor of bone marrow plasma cells.",
      Context_sentence: "The patient was diagnosed with multiple myeloma.",
      Synonyms: "",
      Antonyms: "",
      Topic: "medical"
    ),
    fontColor: .black,
    fontString: "Georgia"
  )
}
