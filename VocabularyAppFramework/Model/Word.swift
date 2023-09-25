//
//  Word.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.

import Foundation
import SwiftUI

struct Word: Hashable, Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let Rank: String
    let List: String
    let Headword: String
    let Definition: String
    let Context_sentence: String
    let Synonyms: String
    let Antonyms: String
    let Topic: String
    var isFavorite: Bool = false
    var isLiked: Bool = false

    enum CodingKeys: String, CodingKey {
        case Rank, List, Headword, Definition, Synonyms, Antonyms, Topic
        case Context_sentence = "Context sentence"
        case isLiked
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        Rank = try container.decode(String.self, forKey: .Rank)
        List = try container.decode(String.self, forKey: .List)
        Headword = try container.decode(String.self, forKey: .Headword)
        Definition = try container.decode(String.self, forKey: .Definition)
        Context_sentence = try container.decode(String.self, forKey: .Context_sentence)
        Synonyms = try container.decode(String.self, forKey: .Synonyms)
        Antonyms = try container.decode(String.self, forKey: .Antonyms)
        Topic = try container.decode(String.self, forKey: .Topic)
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
    }
    
    // Explicit memberwise initializer
    init(id: UUID = UUID(), Rank: String, List: String, Headword: String, Definition: String, Context_sentence: String, Synonyms: String, Antonyms: String, Topic: String, isFavorite: Bool = false, isLiked: Bool = false) {
        self.id = id
        self.Rank = Rank
        self.List = List
        self.Headword = Headword
        self.Definition = Definition
        self.Context_sentence = Context_sentence
        self.Synonyms = Synonyms
        self.Antonyms = Antonyms
        self.Topic = Topic
        self.isFavorite = isFavorite
        self.isLiked = isLiked
    }
}
