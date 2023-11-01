//
//  QCMViewModel.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 28/10/2023.
//

import Foundation
import SwiftUI


extension QCMView {
    class ViewModel : ObservableObject {
        var word: Word
        
        var similarWords : [Word] = []
        var similarWordsArray : [String] = []
        
        init(word: Word) {
            self.word = word
            self.similarWords = WordManager.shared.similarWordsFilterCommonLetters(word: word.Headword, maxCommonLetters: 3, maxSampleSize: 3)
            fillSimilarWordsArray()
        }
        
        func fillSimilarWordsArray() {
            similarWordsArray = similarWords.map { $0.Headword }
             similarWordsArray.append(word.Headword)
             similarWordsArray = similarWordsArray.shuffled()
         }
        
        func cleanWordDescription(word: Word) -> String {
            let placeholder = String(repeating: "_", count: word.Headword.count)
            return word.Definition.replacingOccurrences(of: word.Headword, with: placeholder, options: .caseInsensitive)
        }
        
    }
}
