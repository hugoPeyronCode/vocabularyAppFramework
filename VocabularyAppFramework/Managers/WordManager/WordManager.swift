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

    var allWords: [Word] = []
    var wordsByCategory: [String: [Word]] = [:]

    private init() {
        // Load words from saved data if available, else from bundled JSON
        
        // TO DO -> ADD the logic that make it so that allWords is not 25K words but a fraction of it so that the LazyVStack does not lag
        if let savedWords = UserDataStorage.shared.loadWords() {
            print("Loading from saved data...")
            self.allWords = savedWords
        } else if let wordsFromJSON = JSONParser.parseWord1(from: "words") {
            print("Loading from bundled JSON...")
            self.allWords = wordsFromJSON
            UserDataStorage.shared.saveWords(self.allWords)
        }

        // Populate wordsByCategory using the allWords
        for word in allWords {
            let topic = word.Topic
            if wordsByCategory[topic] != nil {
                wordsByCategory[topic]!.append(word)
            } else {
                wordsByCategory[topic] = [word]
            }
        }
    }

    func toggleLike(for word: Word) {
        print("Toggling like for word: \(word.Headword)")
        if let index = allWords.firstIndex(where: { $0.Headword == word.Headword }) {
            allWords[index].isLiked.toggle()
            UserDataStorage.shared.saveWords(allWords)
            print(" \(allWords[index].Headword) is liked = \(allWords[index].isLiked)")
        } else {
            print("Word not found in allWords array.")
        }
    }

}

