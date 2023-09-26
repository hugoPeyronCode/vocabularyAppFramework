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
        let allWordsFromHome : Set<Word> = WordManager.shared.allWords
        let wordsByCategories : [String: Set<Word>]  = WordManager.shared.wordsByCategory
        
        WindowGroup {
            Home(allWords: allWordsFromHome, wordsByCategories: wordsByCategories)
        }
    }
}


// Le flow que je veux mettre en place

// Load le JSON

// Modifie le set AllWords

// Save le JSON depuis le set allWords modifié

// Repeat

