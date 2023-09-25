//
//  UserDataStorage.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 22/09/2023.
//

import Foundation
import SwiftUI

class UserDataStorage {

    static let shared = UserDataStorage()
    
    private let wordsFilename = "savedWords.json"

    private var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(wordsFilename)
    }

    func saveWords(_ words: Set<Word>) {
        do {
            let wordsArray = Array(words) // Convert set to array
            let data = try JSONEncoder().encode(wordsArray)
            try data.write(to: fileURL)
        } catch {
            print("Error saving words: \(error)")
        }
    }

    func loadWords() -> Set<Word>? {
        do {
            let data = try Data(contentsOf: fileURL)
            let wordsArray = try JSONDecoder().decode([Word].self, from: data)
            return Set(wordsArray) // Convert array back to set
        } catch {
            print("Error loading words: \(error)")
        }
        return nil
    }
}
