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
    @StateObject private var storeKitManager = StoreKitManager()
    let haptic = HapticManager.shared
    
    let allWordsFromHome : Set<Word> = WordManager.shared.allWords
    let wordsByCategories : [String: Set<Word>]  = WordManager.shared.wordsByCategory
    
    var body: some Scene {
        WindowGroup {
            Home(allWords: allWordsFromHome, wordsByCategories: wordsByCategories)
                .onAppear(perform: {
                    haptic.prepareHaptic()
                })
                .environmentObject(themesManager)
                .environmentObject(storeKitManager)
                .task {
                    await storeKitManager.updatePurchasedProducts()
                }
        }
    }
}
