//
//  HomeViewModel.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import Foundation
import SwiftUI

class HomeViewModel: ObservableObject {
    
    // UI and Navigation Variable
    @Published var isShowingPremiumView = false
    @Published var isShowingCategoriesView = false
    @Published var isShowingThemesView = false
    @Published var isShowingSettingsView = false
    @Published var currentPage: Int = 0
    
    // User selection
    @Published var selectedCategory: String = "All"
    @Published var selectedCategories : [String] = []
    
    // Data
    var allWords: Set<Word>
    var wordsByCategory : [String: Set<Word>]
    
    init(allWords: Set<Word>, wordsByCategory: [String: Set<Word>]) {
        self.allWords = allWords
        self.wordsByCategory = wordsByCategory
    }
    
    var filteredWords: Set<Word> {
        if !selectedCategories.isEmpty {
            if selectedCategories.contains("All") {
                return allWords
            }
            
            if selectedCategories.contains("My Favorites") {
                return allWords.filter { $0.isLiked }
            }
            
            var filtered: Set<Word> = []
            for category in selectedCategories {
                filtered.formUnion(words(forCategory: category))
            }
            
            return filtered
        } else if selectedCategory == "All" {
            return allWords
        } else if selectedCategory == "My Favorites" {
            return allWords.filter { $0.isLiked }
        } else {
            return words(forCategory: selectedCategory)
        }
    }
    
    func toggleLike(for word: Word) {
        print("Toggling like for word: \(word.Headword)")

        if allWords.contains(word) {
            var updatedWord = word
            updatedWord.isLiked.toggle()
            allWords.remove(word)
            allWords.insert(updatedWord)
            UserDataStorage.shared.saveWords(allWords)
            print(" \(updatedWord.Headword) is liked = \(updatedWord.isLiked)")
        } else {
            print("Word not found in allWords set.")
        }
    }
    
    func refreshWords() {
        self.objectWillChange.send()
    }
    
    func words(forCategory category: String) -> Set<Word> {
        return wordsByCategory[category] ?? []
    }
    
    func wordsForCategories(categories: [String]) -> Set<Word> {
        var result: Set<Word> = []
        
        for category in categories {
            result.formUnion(words(forCategory: category))
        }
        
        return result
    }
}

