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
    case manga
    case textures
    case landscapes
}

extension ThemesCategories {
    var displayName: String {
        switch self {
        case .colors:
            return "Color"
        case .manga:
            return "Manga"
        case .landscapes:
            return "Landscape"
        case .textures:
            return "Texture"
        }
    }
}

class ThemesManager : ObservableObject {
        
    @Published var currentTheme: Theme
    
    @Published var themesDict: [ThemesCategories: [Theme]] = [
        .colors: [
            // Black White, White Black, Gris / Blanc, Blanc / Gris, Orange, Jaune, Rouge, Rose,
            Theme(backgroundImage: "Black", font: "AmericanTypewriter", fontColor: .white),// VALID
            Theme(backgroundImage: "White", font: "AmericanTypewriter", fontColor: .black),// VALID
            Theme(backgroundImage: "Green", font: "Baskerville", fontColor: .black),
            Theme(backgroundImage: "Anthracite", font: "Impact", fontColor: .gray),
            Theme(backgroundImage: "Pink", font: "Palatino-Bold", fontColor: .pink), // VALID
            Theme(backgroundImage: "Gray", font: "Optima-Bold", fontColor: .orange),
            Theme(backgroundImage: "Cream", font: "Cochin", fontColor: .black),
            Theme(backgroundImage: "Brown", font: "Chalkduster", fontColor: .white),
            Theme(backgroundImage: "Purple", font: "Futura-Medium", fontColor: .blue),
            Theme(backgroundImage: "Yellow", font: "Cochin-Bold", fontColor: .brown)
        ],
        .textures: [
            Theme(backgroundImage: "BlackTexture", font: "Chalkduster", fontColor: .white), // VALID
            Theme(backgroundImage: "BlackTexture1", font: "Impact", fontColor: .white),
            Theme(backgroundImage: "BrownTexture1", font: "TimesNewRomanPSMT", fontColor: .black),
            Theme(backgroundImage: "GreenTexture1", font: "Impact", fontColor: .white), // VALID
            Theme(backgroundImage: "GreenTexture2", font: "Optima-Bold", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "GreenTexture3", font: "AmericanTypewriter", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "GreenTexture4", font: "Cochin-Bold", fontColor: .white),
            Theme(backgroundImage: "PurpleTexture1", font: "Palatino-Bold", fontColor: .white),
            Theme(backgroundImage: "PurpleTexture2", font: "Impact", fontColor: .white), // VALID
            Theme(backgroundImage: "YellowTexture1", font: "Futura-Medium", fontColor: .black),
            Theme(backgroundImage: "YellowTexture2", font: "AmericanTypewriter-CondensedBold", fontColor: .black),
            Theme(backgroundImage: "RedWhiteBlue", font: "Baskerville", fontColor: .black),
            Theme(backgroundImage: "RedWhiteYellow", font: "TimesNewRomanPSMT", fontColor: .black),
            Theme(backgroundImage: "TexturePastels1", font: "Impact", fontColor: .white)
        ],
        .landscapes: [
            Theme(backgroundImage: "Ice", font: "BodoniSvtyTwoITCTT-Bold", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "TropicalForest", font: "Futura-Medium", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "Island", font: "Arial-BoldItalicMT", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "Wave", font: "HoeflerText-Italic", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "Montain", font: "AmericanTypewriter", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "Sunset", font: "AcademyEngravedLetPlain", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "Desert", font: "AmericanTypewriter-CondensedBold", fontColor: .black),
            Theme(backgroundImage: "Autumn", font: "Impact", fontColor: .white, needContrast: true),
        ],
        .manga: [
            Theme(backgroundImage: "DesertManga", font: "AmericanTypewriter-CondensedBold", fontColor: .black, needContrast: true),
            Theme(backgroundImage: "FlyingCastle", font: "Noteworthy-Bold", fontColor: .white, needContrast: true), // Valid
            Theme(backgroundImage: "IslandManga", font: "Impact", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "IslandManga2", font: "Chalkduster", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "MangaRiver", font: "Futura-Medium", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "MangaHarbour", font: "AmericanTypewriter", fontColor: .white, needContrast: true),
            Theme(backgroundImage: "MangaRoad", font: "Baskerville", fontColor: .white, needContrast: true)
        ]
    ]
    
    init() {
        currentTheme = Theme(backgroundImage: "Main", font: "STIXTwoText", fontColor: .primary)
        themesDict[.colors]?.insert(currentTheme, at: 0)
    }
    
    func ChangeCurrentTheme(newTheme : Theme) {
        currentTheme = newTheme
    }
}
