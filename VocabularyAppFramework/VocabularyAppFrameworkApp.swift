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
        let allWords : Set<Word> = WordManager.shared.allWords
        let wordsByCategories : [String: Set<Word>]  = WordManager.shared.wordsByCategory
        
        WindowGroup {
            Home(allWords: allWords, wordsByCategories: wordsByCategories)
        }
    }
}
