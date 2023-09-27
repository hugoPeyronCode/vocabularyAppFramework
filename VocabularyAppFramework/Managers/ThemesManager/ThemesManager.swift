//
//  ThemesManager.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 26/09/2023.
//

import Foundation
import SwiftUI

enum ThemesCategories : CaseIterable {
    case colors
    case cozy
    case landscapes
    case textures
    case manga
}

class ThemesManager : ObservableObject {
    
    @Published var currentTheme: Theme
    
    
    @Published var themesDict: [ThemesCategories: [Theme]] = [
        .colors: [
            // Black White, White Black, Gris / Blanc, Blanc / Gris, Orange, Jaune, Rouge, Rose,
            Theme(backgroundImage: "Black", font: .body, fontColor: .white),
            Theme(backgroundImage: "White", font: .body, fontColor: .black),
            Theme(backgroundImage: "Green", font: .body, fontColor: .white),
            Theme(backgroundImage: "Gray", font: .body, fontColor: .white),
            Theme(backgroundImage: "Pink", font: .body, fontColor: .white),
            Theme(backgroundImage: "Purple", font: .body, fontColor: .black),
            Theme(backgroundImage: "Cream", font: .body, fontColor: .black),
            Theme(backgroundImage: "Brown", font: .body, fontColor: .black),
            Theme(backgroundImage: "Yellow", font: .body, fontColor: .black)

        ],
        .cozy: [
            Theme(backgroundImage: "Office1", font: .body, fontColor: .white)
        ],
        .textures: [
            Theme(backgroundImage: "BlackTexture", font: .body, fontColor: .white),
            Theme(backgroundImage: "BlackTexture1", font: .body, fontColor: .white),
            Theme(backgroundImage: "BrownTexture1", font: .body, fontColor: .white),
            Theme(backgroundImage: "GreenTexture1", font: .body, fontColor: .white),
            Theme(backgroundImage: "GreenTexture2", font: .body, fontColor: .white),
            Theme(backgroundImage: "GreenTexture3", font: .body, fontColor: .white),
            Theme(backgroundImage: "GreenTexture4", font: .body, fontColor: .white),
            Theme(backgroundImage: "PurpleTexture1", font: .body, fontColor: .white),
            Theme(backgroundImage: "PurpleTexture2", font: .body, fontColor: .white),
            Theme(backgroundImage: "YellowTexture1", font: .body, fontColor: .white),
            Theme(backgroundImage: "YellowTexture2", font: .body, fontColor: .white),
            Theme(backgroundImage: "RedWhiteBlue", font: .body, fontColor: .black),
            Theme(backgroundImage: "RedWhiteYellow", font: .body, fontColor: .black),
            Theme(backgroundImage: "TexturePastels1", font: .body, fontColor: .black)
        ],
        .landscapes: [
            Theme(backgroundImage: "Ice", font: .body, fontColor: .black),
            Theme(backgroundImage: "TropicalForest", font: .body, fontColor: .white),
            Theme(backgroundImage: "Island", font: .body, fontColor: .white),
            Theme(backgroundImage: "Wave", font: .body, fontColor: .black),
            Theme(backgroundImage: "Montain", font: .body, fontColor: .white),
            Theme(backgroundImage: "Sunset", font: .body, fontColor: .white),
            Theme(backgroundImage: "Desert", font: .body, fontColor: .white),
            Theme(backgroundImage: "Autumn", font: .body, fontColor: .white),
        ],
        .manga: [
            Theme(backgroundImage: "DesertManga", font: .body, fontColor: .black),
            Theme(backgroundImage: "FlyingCastle", font: .body, fontColor: .white),
            Theme(backgroundImage: "IslandManga", font: .body, fontColor: .white),
            Theme(backgroundImage: "IslandManga2", font: .body, fontColor: .white),
            Theme(backgroundImage: "MangaRiver", font: .body, fontColor: .white),
            Theme(backgroundImage: "MangaHarbour", font: .body, fontColor: .black),
            Theme(backgroundImage: "MangaRoad", font: .body, fontColor: .black)
        ]
    ]
    
    init() {
        currentTheme = Theme(backgroundImage: "Main", font: .body, fontColor: .primary)
    }
    
    func ChangeCurrentTheme(newTheme : Theme) {
        currentTheme = newTheme
    }
}
