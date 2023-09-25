//
//  VocabularyAppFrameworkApp.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

@main
struct VocabularyAppFrameworkApp: App {
    var body: some Scene {
        
        // Ici je veux initialiser mon Array de mot allWords.
        let allWords : [Word] = Array(WordManager.shared.allWords.shuffled().prefix(2000))
        let wordsByCategories : [ String: [Word]]  = WordManager.shared.wordsByCategory
        
        WindowGroup {
            Home(allWords: allWords, wordsByCategories: wordsByCategories)
        }
    }
}
