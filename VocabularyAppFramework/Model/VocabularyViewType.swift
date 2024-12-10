//
//  VocabularyViewType.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 10/12/2024.
//

import Foundation

enum VocabularyViewType {
    case wordDisplay    // Simple word display
    case wordWriting    // Letter tapping exercise
    case fillInBlanks   // Text with missing letters
    case anagrams       // Word anagram selection
}

extension HomeViewModel {
    func getViewType(for index: Int) -> VocabularyViewType {
        // You can implement different logic here, for example:
        // - Every 3rd word is writing exercise
        // - Every 5th word is fill in blanks
        // - Every 7th word is anagrams
        // - Rest are simple display

        if index % 7 == 0 {
            return .anagrams
        } else if index % 5 == 0 {
            return .fillInBlanks
        } else if index % 3 == 0 {
            return .wordWriting
        } else {
            return .wordDisplay
        }
    }
}
