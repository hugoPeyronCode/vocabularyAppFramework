//
//  Theme.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 26/09/2023.
//

import Foundation
import SwiftUI

struct Theme: Identifiable, Hashable {
    let id = UUID()
    let backgroundImage: String
    let font: String
    let fontColor: Color
    let needContrast: Bool?
    
    init(backgroundImage: String, font: String, fontColor: Color, needContrast: Bool? = nil) {
        self.backgroundImage = backgroundImage
        self.font = font
        self.fontColor = fontColor
        self.needContrast = needContrast
    }
}

