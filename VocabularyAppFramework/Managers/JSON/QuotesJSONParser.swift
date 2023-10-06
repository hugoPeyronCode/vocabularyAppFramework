//
//  QuotesJSONParser.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 04/10/2023.
//

import Foundation

struct Quote: Decodable {
    let Definition: String
    let author: String
    let Topic: String
}

func loadQuotes() -> [Word] {
    guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json") else {
        fatalError("Failed to locate quotes.json in app bundle")
    }

    guard let data = try? Data(contentsOf: url) else {
        fatalError("Failed to load quotes.json from app bundle")
    }

    let decoder = JSONDecoder()
    guard let loadedQuotes = try? decoder.decode([Quote].self, from: data) else {
        fatalError("Failed to decode quotes.json from app bundle")
    }

    // Convert Quote objects to Word objects
    return loadedQuotes.map { Word(Definition: $0.Definition, Topic: $0.Topic) }
}
