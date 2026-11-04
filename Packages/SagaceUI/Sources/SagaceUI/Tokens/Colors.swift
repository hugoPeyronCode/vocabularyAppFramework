import SwiftUI
import UIKit

// Couleurs de `02_DESIGN_SYSTEM.md` section 2. Aucune couleur littérale ailleurs que dans ce fichier.

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    /// Couleur dynamique clair / sombre sans passer par l'asset catalog.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

public extension Color {
    // MARK: Neutres
    static let vBackground      = Color(light: 0xE0E0E0, dark: 0x181818)
    static let vBackgroundDeep  = Color(light: 0xD2D2D2, dark: 0x111111)
    static let vSurface         = Color(light: 0xFDFDFD, dark: 0x212121)
    static let vSurfaceRaised   = Color(light: 0xF0F0F0, dark: 0x2C2C2C)
    static let vSurfaceSelected = Color(light: 0xD8D8D8, dark: 0x333333)
    static let vSeparator       = Color(light: 0xE3E3E3, dark: 0x323232)
    static let vTextPrimary     = Color(light: 0x111111, dark: 0xFFFFFF)
    static let vTextSecondary   = Color(light: 0x6B6B6B, dark: 0x8E8E8E)
    static let vTextGhost       = Color(light: 0xE8E8E8, dark: 0x2A2A2A)
    static let vInverse         = Color(light: 0x1C1C1C, dark: 0xE5E5E5)
    /// Texte posé sur `vInverse` (pilule active, bouton de confirmation, niveau Expert).
    static let vOnInverse       = Color(light: 0xFDFDFD, dark: 0x111111)

    // MARK: Accents
    static let vBlue            = Color(hex: 0x285DF0)
    static let vBluePressed     = Color(hex: 0x3653F5)
    static let vPurple          = Color(hex: 0x7129EE)
    static let vPurpleSoft      = Color(hex: 0x995FF2)
    static let vAvatar          = Color(hex: 0xD1ADA8)
    /// Texte et icônes posés sur un accent ou une couleur de niveau.
    static let vOnAccent        = Color(hex: 0xFFFFFF)

    // MARK: Feedback de quiz
    static let vCorrect         = Color(light: 0x28B44C, dark: 0x30D158)
    static let vIncorrect       = Color(hex: 0xF83328)

    // MARK: Niveaux
    static let vLevelDebutantDot      = Color(hex: 0x8E8E8E)
    static let vLevelDebutantSelected = Color(hex: 0x3A3A3A)
    static let vLevelElementaire      = Color(hex: 0xA444D8)
    static let vLevelIntermediaire    = Color(hex: 0xF83328)
    static let vLevelAvance           = Color(hex: 0x9B7752)

    // MARK: Ombre
    /// Ombre de la carte du jour, en clair uniquement (`y 10, blur 30, noir 8 %`).
    static let vCardShadow = Color(white: 0, opacity: 0.08)
}

public extension ShapeStyle where Self == Color {
    static var vBackground: Color { .vBackground }
    static var vBackgroundDeep: Color { .vBackgroundDeep }
    static var vSurface: Color { .vSurface }
    static var vSurfaceRaised: Color { .vSurfaceRaised }
    static var vSurfaceSelected: Color { .vSurfaceSelected }
    static var vSeparator: Color { .vSeparator }
    static var vTextPrimary: Color { .vTextPrimary }
    static var vTextSecondary: Color { .vTextSecondary }
    static var vTextGhost: Color { .vTextGhost }
    static var vInverse: Color { .vInverse }
    static var vOnInverse: Color { .vOnInverse }
    static var vBlue: Color { .vBlue }
    static var vPurple: Color { .vPurple }
    static var vPurpleSoft: Color { .vPurpleSoft }
    static var vAvatar: Color { .vAvatar }
    static var vOnAccent: Color { .vOnAccent }
    static var vCorrect: Color { .vCorrect }
    static var vIncorrect: Color { .vIncorrect }
}
