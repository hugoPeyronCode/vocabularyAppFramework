//
//  HomeViewModel.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

@Observable
class HomeViewModel {
  var isShowingPremiumView = false
  var isShowingCategoriesView = false
  var isShowingThemesView = false
  var isShowingSettingsView = false
  var isShowingQuizzSettingsView = false
  var currentPage: Int = 0

  var selectedCategory: String = "all"
  var selectedCategories: [String] = []

  var quizzApparitionValue: Int = 5 {
    didSet {
      UserDefaults.standard.set(quizzApparitionValue, forKey: "quizApparitionValue")
    }
  }

  private var allWordsLimits: Int = 2000

  // Data
  var allWords: [Word]
  var wordsByCategory: [String: [Word]]

  init(allWords: Set<Word>, wordsByCategory: [String: Set<Word>]) {
    self.allWords = Array(allWords)
    self.wordsByCategory = wordsByCategory.mapValues { Array($0) }
    self.quizzApparitionValue = UserDefaults.standard.integer(forKey: "quizApparitionValue")
    if self.quizzApparitionValue == 0 {
      self.quizzApparitionValue = 5
    }
  }

  var filteredWords: [Word] {
    if !selectedCategories.isEmpty {
      if selectedCategories.contains("all") {
        return Array(allWords.prefix(allWordsLimits))
      }

      if selectedCategories.contains("My Favorites") {
        return allWords.filter { $0.isLiked }
      }

      var filtered: [Word] = []
      for category in selectedCategories {
        filtered.append(contentsOf: words(forCategory: category))
      }
      return filtered

    } else if selectedCategory == "all" {
      return Array(allWords.prefix(allWordsLimits))
    } else if selectedCategory == "My Favorites" {
      return allWords.filter { $0.isLiked }
    } else {
      return words(forCategory: selectedCategory)
    }
  }

  func toggleLike(for word: Word) {
    print("Toggling like for word: \(word.Headword)")

    if let index = allWords.firstIndex(where: { $0.id == word.id }) {
      var wordToUpdate = allWords[index]
      wordToUpdate.isLiked.toggle()
      allWords[index] = wordToUpdate

      UserDataStorage.shared.saveWords(Set(allWords))  // Assuming saveWords still expects a Set

      print("\(wordToUpdate.Headword) is liked = \(wordToUpdate.isLiked)")
    } else {
      print("Word not found in allWords array.")
    }
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
