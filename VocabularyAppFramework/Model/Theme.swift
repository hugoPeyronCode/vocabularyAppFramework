//
//  Theme.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 26/09/2023.
//

import Foundation
import SwiftUI

struct Theme : Identifiable, Hashable {
    let id = UUID()
    let backgroundImage : String
    let font : Font
    let fontColor : Color
}

extension ThemesCategories {
    var displayName: String {
        switch self {
        case .colors:
            return "Color"
        case .cozy:
            return "Cozy"
        case .photos:
            return "Photo"
        case .books:
            return "Books"
        case .landscapes:
            return "Landscape"
        case .textures:
            return "Texture"
        case .manga:
            return "Manga"
        }
    }
}

