//
//  WordManager.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 21/09/2023.
//
import Foundation
import SwiftUI

class WordManager {
    static let shared = WordManager()

    var allWords: Set<Word> = []
    var wordsByCategory: [String: Set<Word>] = [:]

    private init() {
        // Load words from saved data if available, else from bundled JSON
        
        // TO DO -> ADD the logic that make it so that allWords is not 25K words but a fraction of it so that the LazyVStack does not lag
        if let savedWords = UserDataStorage.shared.loadWords() {
            print("Loading from saved data...")
            self.allWords = Set(savedWords)
        } else if let wordsFromJSON = JSONParser.parseWord1(from: "words") {
            print("Loading from bundled JSON...")
            self.allWords = wordsFromJSON
            UserDataStorage.shared.saveWords(self.allWords)
        }

        // Populate wordsByCategory using the allWords
        for word in allWords {
            let topic = word.Topic
            if wordsByCategory[topic] != nil {
                wordsByCategory[topic]!.insert(word)
            } else {
                wordsByCategory[topic] = [word]
            }
        }
    }
    
    func similarWordsFilterCommonLetters(word: String, maxCommonLetters: Int, maxSampleSize: Int) -> [Word] {
        var commonLetters = maxCommonLetters
        var filteredData = allWords.filter {
            word.prefix(commonLetters) == $0.Headword.prefix(commonLetters) && word != $0.Headword
        }
        
        while filteredData.count < maxSampleSize && commonLetters > 0 {
            commonLetters -= 1
            filteredData = allWords.filter {
                word.prefix(commonLetters) == $0.Headword.prefix(commonLetters) && word != $0.Headword
            }
        }
        
        var shuffledData = Array(filteredData)
        shuffledData.shuffle()

        return Array(shuffledData.prefix(maxSampleSize))
    }
}

