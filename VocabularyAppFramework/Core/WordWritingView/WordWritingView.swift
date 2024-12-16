//
//  WordWritingView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 29/11/2024.
//

import SwiftUI

struct WordWritingView: View {
  @EnvironmentObject var themesManager: ThemesManager

  @State private var vm: WordWritingViewModel

  init(word: Word, fontColor: Color, fontString: String) {
    _vm = State(initialValue: WordWritingViewModel(
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
        VStack() {
          WordToComplete
          if !vm.isComplete {
            LetterGrid(geometry: geometry)
          } else {
            WordContent
          }
        }
        Spacer()
      }
      .padding()
      .foregroundColor(vm.fontColor)
      .shadow(radius: vm.fontColor == .white ? 1 : 0)
    }
    .animation(.default, value: vm.isComplete)
    .onChange(of: themesManager.currentTheme) { _ , _ in
      updateViewModel()
    }
  }

  private var WordToComplete : some View {
    HStack(spacing: 1) {
      ForEach(Array(vm.word.Headword.enumerated()), id: \.offset) { index, letter in
        Text(String(letter))
          .minimumScaleFactor(0.7)
          .font(.custom(vm.fontString, size: 40))
          .foregroundStyle(vm.selectedLetters.count > index ? vm.fontColor : vm.fontColor.opacity(0.3))
      }
    }
  }

  private var WordContent: some View {
    VStack() {
      WordDefinitionView(word: vm.word, fontColor: vm.fontColor, fontString: vm.fontString)
      WordSentenceView(word: vm.word, fontColor: vm.fontColor, fontString: vm.fontString)
    }
    .animation(.smooth(duration: 1), value: vm.isComplete)
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
  WordWritingView(
    word: Word(
      Rank: "1",
      List: "Bob",
      Headword: "voca",
      Definition: "Ensemble des mots, des vocables d'une langue, très très longue definition pour voir si ça dépasse les limites de la preview",
      Context_sentence: "khjh",
      Synonyms: "jh",
      Antonyms: "jhj",
      Topic: "Bob"
    ),
    fontColor: .black,
    fontString: "Georgia"
  )
  .environmentObject(ThemesManager())
}
