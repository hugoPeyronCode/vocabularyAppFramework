import SwiftUI
import Testing
import UIKit
@testable import SagaceUI

@MainActor
@Suite("Carte de partage")
struct ShareCardTests {
    let card = ShareCard(
        familyName: "Paronymes", headword: "éminent", meta: Text(verbatim: "adj. · /e.mi.nɑ̃/"),
        definition: "Qui se distingue des autres par son mérite ou son rang",
        confusion: ShareCard.Confusion(word: "imminent", meaning: "Qui va se produire très prochainement")
    )

    /// Luminance moyenne d'une zone de l'image (0 = noir, 1 = blanc).
    private func luminance(of image: UIImage, at point: CGPoint) throws -> Double {
        let cgImage = try #require(image.cgImage)
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = try #require(CGContext(
            data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        let x = point.x * CGFloat(cgImage.width)
        let y = point.y * CGFloat(cgImage.height)
        context.draw(cgImage, in: CGRect(x: -x, y: -(CGFloat(cgImage.height) - y), width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
        return (0.2126 * Double(pixel[0]) + 0.7152 * Double(pixel[1]) + 0.0722 * Double(pixel[2])) / 255
    }

    @Test("S'exporte en image en clair et en sombre, à la taille prévue")
    func exportsBothAppearances() throws {
        let light = try #require(card.image(colorScheme: .light, scale: 2))
        let dark = try #require(card.image(colorScheme: .dark, scale: 2))
        let expected = CGSize(width: ShareCard.size.width + 32, height: ShareCard.size.height + 32)
        #expect(light.size == expected)
        #expect(dark.size == expected)
        // Coin de la carte, hors texte : surface claire (#FDFDFD) ou sombre (#212121).
        let corner = CGPoint(x: 0.12, y: 0.12)
        #expect(try luminance(of: light, at: corner) > 0.9)
        #expect(try luminance(of: dark, at: corner) < 0.2)
    }
}
