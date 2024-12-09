//
//  WordWritingView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 29/11/2024.
//

import SwiftUI

struct WordWritingView: View {
    @State private var vm: WordWritingViewModel

    init(word: Word, fontColor: Color, fontString: String) {
        _vm = State(initialValue: WordWritingViewModel(
            word: word,
            fontColor: fontColor,
            fontString: fontString
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: 50) {
                Spacer()
                WordToComplete(geometry: geometry)
                WordContent
                LetterGrid(geometry: geometry)
                Spacer()
            }
            .lineLimit(nil)
            .multilineTextAlignment(.center)
            .foregroundColor(vm.fontColor)
            .shadow(radius: vm.fontColor == .white ? 1 : 0)
            .padding()
            .font(.custom(vm.fontString, size: 45))
        }
    }

    @ViewBuilder
    var WordContent: some View {
        VStack(spacing: 20) {
            Text(!vm.isComplete ? " " : vm.word.Definition)
                .frame(height: 100)
                .font(.custom(vm.fontString, size: 19))

            Text(!vm.isComplete ? " " : "(\(vm.word.Context_sentence))")
                .frame(height: 50)
                .font(.custom(vm.fontString, size: 15))
        }
        .animation(.smooth(duration: 1), value: vm.isComplete)
        .lineLimit(nil)
        .multilineTextAlignment(.center)
        .foregroundColor(vm.fontColor)
        .shadow(radius: vm.fontColor == .white ? 1 : 0)
    }

    private func WordToComplete(geometry: GeometryProxy) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(vm.word.Headword.enumerated()), id: \.offset) { index, letter in
                Text(String(letter).uppercased())
                    .font(.custom(vm.fontString, size: min(geometry.size.width / CGFloat(Double(vm.word.Headword.count) * 1.5), 46)))
                    .bold()
                    .foregroundStyle(vm.selectedLetters.count > index ? .black : .gray.opacity(0.3))
            }
        }
    }

  private func LetterGrid(geometry: GeometryProxy) -> some View {
      let columns = [
          GridItem(.adaptive(minimum: min(geometry.size.width / 8, 60), maximum: 60), spacing: 8)
      ]

      return VStack {
          Spacer()
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
          Spacer()
      }
  }
}

#Preview {
  WordWritingView(
    word: Word(
      Rank: "1",
      List: "Bob",
      Headword: "voca",
      Definition: "Ensemble des mots, des vocables d'une langue",
      Context_sentence: "khjh",
      Synonyms: "jh",
      Antonyms: "jhj",
      Topic: "Bob"
    ),
    fontColor: .black,
    fontString: "Georgia"
  )
}
