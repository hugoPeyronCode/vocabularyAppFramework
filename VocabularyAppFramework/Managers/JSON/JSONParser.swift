//
//  JSONParser.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 21/09/2023.
//

import Foundation
import SwiftUI

class JSONParser {
    
    static func parseWord1(from filename: String) -> Set<Word>? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to locate or read from \(filename).json in bundle.")
            return nil
        }
        
        let decoder = JSONDecoder()
        
        do {
            let wordsArray = try decoder.decode([Word].self, from: data)
            return Set(wordsArray)
        } catch let DecodingError.dataCorrupted(context) {
            print("Data corrupted: \(context)")
            print("Debug description: \(context.debugDescription)")
            print("Coding path for corrupted data: \(context.codingPath)")
            return nil
        } catch let DecodingError.keyNotFound(key, context) {
            print("Missing key: \(key.stringValue)")
            print("Debug description: \(context.debugDescription)")
            print("Coding path for key not found: \(context.codingPath)")
            return nil
        } catch let DecodingError.typeMismatch(type, context)  {
            print("Type mismatch: \(type)")
            print("Debug description: \(context.debugDescription)")
            print("Coding path for type mismatch: \(context.codingPath)")
            return nil
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value not found: \(value)")
            print("Debug description: \(context.debugDescription)")
            print("Coding path for value not found: \(context.codingPath)")
            return nil
        } catch {
            print("Decoding error: \(error.localizedDescription)")
            return nil
        }
    }
}
