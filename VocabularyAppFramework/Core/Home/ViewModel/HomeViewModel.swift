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
    var allWords: [Word]
    var wordsByCategory : [ String : [Word] ]
    
    init(allWords : [Word], wordsByCategory: [String : [Word]]) {
        self.allWords = allWords
        self.wordsByCategory = wordsByCategory
    }
    
    var filteredWords: [Word] {
        if !selectedCategories.isEmpty {
            if selectedCategories.contains("All") {
                return allWords
            }
            
            if selectedCategories.contains("My Favorites") {
                return allWords.filter { $0.isLiked }
            }
            
            var filtered: [Word] = []
            for category in selectedCategories {
                filtered.append(contentsOf: words(forCategory: category))
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
    
    func refreshWords() {
        self.objectWillChange.send()
    }
    
    func words(forCategory category: String) -> [Word] {
        return wordsByCategory[category] ?? []
    }
    
    func wordsForCategories(categories: [String]) -> [Word] {
        var result: [Word] = []
        
        for category in categories {
            result.append(contentsOf: words(forCategory: category))
        }
        
        return result
    }
}

