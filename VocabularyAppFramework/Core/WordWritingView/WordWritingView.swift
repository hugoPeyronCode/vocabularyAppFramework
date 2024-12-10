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
    .onChange(of: themesManager.currentTheme) { _ , _ in
             updateViewModel()
    }
  }

  private func WordToComplete(geometry: GeometryProxy) -> some View {
    HStack(spacing: 8) {
      ForEach(Array(vm.word.Headword.enumerated()), id: \.offset) { index, letter in
        Text(String(letter).uppercased())
          .font(.custom(vm.fontString, size: min(geometry.size.width / CGFloat(Double(vm.word.Headword.count) * 1.5), 46)))
          .bold()
          .foregroundStyle(vm.selectedLetters.count > index ? vm.fontColor : vm.fontColor.opacity(0.3))
      }
    }
  }

  private var WordContent: some View {
    VStack(spacing: 20) {
      Text(!vm.isComplete ? " " : vm.word.Definition)
        .font(.custom(vm.fontString, size: 19))

      Text(!vm.isComplete ? " " : "(\(vm.word.Context_sentence))")
        .frame(height: 50)
        .font(.custom(vm.fontString, size: 15))
    }
    .minimumScaleFactor(0.7)
    .animation(.smooth(duration: 1), value: vm.isComplete)
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
}
