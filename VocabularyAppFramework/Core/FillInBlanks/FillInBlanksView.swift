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

  private func updateViewModel() {
    vm.fontColor = themesManager.currentTheme.fontColor
    vm.fontString = themesManager.currentTheme.font
  }

  var body: some View {
    GeometryReader { geometry in
      VStack() {
        Spacer()

        WordToComplete(geometry: geometry)
        WordContent

        Spacer()

        showDefinitionEyeButton
          .padding(.bottom)
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

  private var showDefinitionEyeButton: some View {
    Button(action: {
      withAnimation { showHint.toggle() }
    }) {
      Image(systemName: showHint ? "eye.fill" : "eye.slash.fill")
        .font(.title3)
        .foregroundStyle(vm.fontColor.opacity(0.3))
        .padding()
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
