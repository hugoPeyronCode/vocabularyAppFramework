//
//  WordView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct WordView: View {
    
    @ObservedObject var viewModel: HomeViewModel
    @State var word : Word
    
    let fontColor : Color
    let fontString : String
    
//    let sharingAction : () -> Void
//    let likeAction : (Word) -> Void
//    let bookmarkAction : () -> Void
    
    var body: some View {
        VStack(spacing: 90) {

            MainContent
            
            ActionBar
            
        }
        .offset(y: 40)
    }
    
    var MainContent : some View {
        VStack(alignment: .center, spacing: 50) {
            Text(word.Headword)
                .font(.custom(fontString, size: 45))
            Text(word.Definition)
                .font(.custom(fontString, size: 19))
            Text("(\(word.Context_sentence))")
                .font(.custom(fontString, size: 15))
        }
        .lineLimit(nil)
        .multilineTextAlignment(.center)
        .foregroundColor(fontColor)
        .shadow(radius: fontColor == .white ? 1 : 0)
        .padding()
    }
    
    var ActionBar : some View {
        HStack(spacing: 50) {
            
//            Button {
////                sharingAction()
//            } label: {
//                Image(systemName: "square.and.arrow.up")
//            }
            
            Button {
                HapticManager.shared.generateFeedback(for: .successStrong)
                word.isLiked.toggle()
                viewModel.toggleLike(for: word)
            } label: {
                Image(systemName: word.isLiked ? "heart.fill" : "heart")
                    .foregroundColor(word.isLiked ? .main : fontColor)
            }
            
//            Button {
////                bookmarkAction()
//            } label: {
//                Image(systemName: "bookmark")
//            }
        }
        .font(.title)
        .fontWeight(.thin)
        .foregroundColor(.primary)
        .shadow(radius: fontColor == .white ? 1 : 0)
    }
}

struct WordView_Previews: PreviewProvider {
    
    static var word = Word(Rank: "", List: "", Headword: "Example", Definition: "Super definition du mot example", Context_sentence: "An example is exactly what you see right now", Synonyms: "", Antonyms: "", Topic: "other")
    
    static var previews: some View {
        WordView(viewModel: HomeViewModel(allWords: WordManager.shared.allWords , wordsByCategory: WordManager.shared.wordsByCategory), word: word, fontColor: .black, fontString: "STIXTwoText")
    }
}

// Georgia
// STIXTwoMath-Regular
