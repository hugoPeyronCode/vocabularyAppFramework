//
//  WordView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct WordView: View {
    
    @ObservedObject var viewModel: WordViewModel
    
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
            Text(viewModel.word.Headword)
                .font(.system(size: 45))
            Text(viewModel.word.Definition)
                .font(.title3)
            Text("(\(viewModel.word.Context_sentence))")
                .font(.subheadline)
        }
        .lineLimit(nil)
        .multilineTextAlignment(.center)
        .fontDesign(.serif)
        .padding()
    }
    
    var ActionBar : some View {
        HStack(spacing: 50) {
            
            Button {
//                sharingAction()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            
            Button {
                viewModel.toggleLike()
            } label: {
                Image(systemName: viewModel.word.isLiked ? "heart.fill" : "heart")
                    .foregroundColor(viewModel.word.isLiked ? .main : .primary)
            }
            
            Button {
//                bookmarkAction()
            } label: {
                Image(systemName: "bookmark")
            }
        }
        .font(.title)
        .fontWeight(.thin)
        .foregroundColor(.primary)
    }
}

struct WordView_Previews: PreviewProvider {
    
    static var word = Word(Rank: "", List: "", Headword: "Example", Definition: "Super definition du mot example", Context_sentence: "An example is exactly what you see right now", Synonyms: "", Antonyms: "", Topic: "other")

    
    static var previews: some View {
        WordView(viewModel: WordViewModel(word: word))
    }
}
