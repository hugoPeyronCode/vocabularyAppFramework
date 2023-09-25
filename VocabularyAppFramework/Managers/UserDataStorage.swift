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

    func saveWords(_ words: [Word]) {
        do {
            print("Initiating saving process...")

            // Check if the file exists and move it to a backup location
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let backupURL = fileURL.deletingLastPathComponent().appendingPathComponent("backupWords.json")
                try? FileManager.default.moveItem(at: fileURL, to: backupURL)
            }

            let data = try JSONEncoder().encode(words)
            try data.write(to: fileURL)
            print("Words saved successfully!")
        } catch {
            print("Error saving words: \(error)")
        }
    }

    func loadWords() -> [Word]? {
        print("Initiating loading process...")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            print("File exists at path: \(fileURL.path)")
            do {
                let data = try Data(contentsOf: fileURL)
                let words = try JSONDecoder().decode([Word].self, from: data)
                print("Loaded \(words.count) words successfully!")
                return words
            } catch {
                print("Error loading words: \(error)")
            }
        } else {
            print("File does not exist at path: \(fileURL.path)")
        }
        return nil
    }
}
