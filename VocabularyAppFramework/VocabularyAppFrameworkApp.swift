//
//  VocabularyAppFrameworkApp.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

@main
struct VocabularyAppFrameworkApp: App {
    
    @StateObject var themesManager = ThemesManager()
    
    var body: some Scene {
        let allWordsFromHome : Set<Word> = WordManager.shared.allWords
        let wordsByCategories : [String: Set<Word>]  = WordManager.shared.wordsByCategory
                
        WindowGroup {
            Home(allWords: allWordsFromHome, wordsByCategories: wordsByCategories)
                .environmentObject(themesManager)
//            FontsTestView()
        }
    }
}
