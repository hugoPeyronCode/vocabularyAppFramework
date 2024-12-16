//
//  FillInBlanksView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 10/12/2024.
//

import SwiftUI

struct FillInBlanksView: View {
  @StateObject private var vm: FillInBlanksViewModel
  @EnvironmentObject var themesManager: ThemesManager

  @State private var showHint = false

  init(word: Word, fontColor: Color, fontString: String) {
    _vm = StateObject(wrappedValue: FillInBlanksViewModel(
      word: word,
      fontColor: fontColor,
      fontString: fontString
    ))
  }

  var body: some View {
    GeometryReader { geometry in
      VStack() {

        Spacer()

        WordToComplete(geometry: geometry)
        WordContent

        if !vm.isComplete {
          LetterGrid(geometry: geometry)
        }
        Spacer()

        HintButton
      }
      .animation(.default, value: vm.isComplete)
      .padding()
      .foregroundColor(vm.fontColor)
      .shadow(radius: vm.fontColor == .white ? 1 : 0)
      .font(.custom(vm.fontString, size: 45))
    }
    .onChange(of: vm.isComplete, { oldValue, newValue in
      if newValue {
        showHint = true
      }
    })
    .onChange(of: themesManager.currentTheme) { _, _ in
      updateViewModel()
    }
  }

  private func updateViewModel() {
    vm.fontColor = themesManager.currentTheme.fontColor
    vm.fontString = themesManager.currentTheme.font
  }

  private func WordToComplete(geometry: GeometryProxy) -> some View {
    HStack(spacing: 8) {
      ForEach(Array(vm.word.Headword.enumerated()), id: \.offset) { index, letter in
        if vm.isLetterMasked(at: index) {
          if let maskedIndex = vm.getMaskedLetterIndex(at: index) {
            if maskedIndex < vm.selectedLetters.count {
              // Show the found letter with animation
              Text(String(vm.selectedLetters[maskedIndex]).lowercased())
                .foregroundStyle(vm.isComplete ? vm.fontColor : .main)
                .animation(.easeIn(duration: 1), value: vm.selectedLetters.count)
                .animation(.easeIn(duration: 1), value: vm.isComplete)
            } else {
              // Show underscore for unfound letters
              Text("_")
                .foregroundStyle(
                  maskedIndex == vm.currentHighlightIndex
                  ? .main
                  : vm.fontColor.opacity(0.3)
                )
            }
          }
        } else {
          // Show unmasked letters
          Text(String(letter).lowercased())
            .foregroundStyle(vm.fontColor)
        }
      }
    }
    .font(.custom(vm.fontString, size: 40))
    .animation(.easeInOut(duration: 1), value: vm.selectedLetters)
  }

  private var HintButton: some View {
    HomeSquareButton(text: !showHint ? "Hint" : "Hide", image: "") {
      withAnimation { showHint.toggle() }
    }
    .sensoryFeedback(.alignment, trigger: showHint)
    .opacity(vm.isComplete ? 0 : 1)
  }

  private var WordContent: some View {
    VStack {
      WordDefinitionView(word: vm.word, fontColor: vm.fontColor, fontString: vm.fontString)
      WordSentenceView(word: vm.word, fontColor: vm.fontColor, fontString: vm.fontString)
    }
    .opacity(showHint ? 1 : 0)
    .animation(.easeInOut, value: showHint)
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
  .environmentObject(ThemesManager())
}
