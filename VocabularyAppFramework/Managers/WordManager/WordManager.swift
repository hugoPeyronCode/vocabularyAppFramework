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
}

