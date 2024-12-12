//
//  WordView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct WordView: View {

  @State var viewModel: HomeViewModel
  @State var word : Word
  let fontColor : Color
  let fontString : String

  //    let sharingAction : () -> Void
  //    let likeAction : (Word) -> Void
  //    let bookmarkAction : () -> Void

  var body: some View {
    VStack(spacing: 90) {
      SharedWordContent(word: word, fontColor: fontColor, fontString: fontString)
      ActionBar
    }
    .offset(y: 40)
  }

  var ActionBar : some View {
    HStack(spacing: 50) {
      Button {
        word.isLiked.toggle()
        viewModel.toggleLike(for: word)
      } label: {
        Image(systemName: word.isLiked ? "heart.fill" : "heart")
          .foregroundColor(word.isLiked ? .main : fontColor)
      }
    }
    .sensoryFeedback(.impact, trigger: word.isLiked)
    .font(.title)
    .fontWeight(.thin)
    .foregroundColor(.primary)
    .shadow(radius: fontColor == .white ? 1 : 0)
  }
}

struct WordView_Previews: PreviewProvider {

  static var word = Word(Rank: "", List: "", Headword: "Example", Definition: "An example is exactly what you see right now  An example is exactly what you see right now An example is exactly what you see right now An example is exactly what you see right now An example is exactly what you see right now Super definition du mot example", Context_sentence: "An example is exactly what you see right now", Synonyms: "", Antonyms: "", Topic: "other")

  static var previews: some View {
    WordView(viewModel: HomeViewModel(allWords: WordManager.shared.allWords , wordsByCategory: WordManager.shared.wordsByCategory), word: word, fontColor: .black, fontString: "STIXTwoText")
  }
}

// Georgia
// STIXTwoMath-Regular
