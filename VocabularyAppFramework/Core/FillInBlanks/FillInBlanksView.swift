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

        Spacer()

        LetterGrid(geometry: geometry)

        Spacer()

        EyeButton

      }
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
              Text(String(vm.selectedLetters[maskedIndex]).uppercased())
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
          Text(String(letter).uppercased())
            .foregroundStyle(vm.fontColor)
        }
      }
    }
    .font(.custom(vm.fontString, size: min(geometry.size.width / CGFloat(Double(vm.word.Headword.count) * 1.5), 45)))

    .animation(.easeInOut(duration: 1), value: vm.selectedLetters)
  }

  private var EyeButton: some View {
    Button(action: {
      withAnimation { showHint.toggle() }
    }) {
      Text(" \(showHint ? "Hide" : "Hint")")
        .opacity(vm.isComplete ? 0 : 1)
        .font(.custom(vm.fontString, size: 18))
        .font(.title3)
        .foregroundStyle(showHint ? vm.fontColor.opacity(0.3) :  .blue)
        .padding()
        .sensoryFeedback(.alignment, trigger: showHint)
    }
  }

  private var WordContent: some View {
    VStack(spacing: 20) {
      VStack(spacing: 20) {
        Text(vm.word.Definition)
          .font(.custom(vm.fontString, size: 19))
        Text("(\(vm.word.Context_sentence))")
          .frame(height: 50)

          .font(.custom(vm.fontString, size: 15))
      }
      .opacity(showHint ? 1 : 0)
      .animation(.easeInOut, value: showHint)
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
  .environmentObject(ThemesManager())
}
