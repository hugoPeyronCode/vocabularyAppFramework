import SwiftUI
import UIKit

/// Carte de partage d'une fiche (SHR-01) : carte `surface`, famille en fantôme, mot, définition,
/// confusion, logo Sagace discret en bas. Les textes viennent du contenu.
public struct ShareCard: View {
    public struct Confusion: Equatable, Sendable {
        public let word: String
        public let meaning: String

        public init(word: String, meaning: String) {
            self.word = word; self.meaning = meaning
        }
    }

    let familyName: String
    let headword: String
    let meta: Text
    let definition: String
    let confusion: Confusion?

    public init(familyName: String, headword: String, meta: Text, definition: String, confusion: Confusion?) {
        self.familyName = familyName; self.headword = headword; self.meta = meta
        self.definition = definition; self.confusion = confusion
    }

    /// Taille de l'image exportée, en points (format portrait pour les stories et messages).
    public static let size = CGSize(width: 360, height: 450)

    public var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Text(verbatim: familyName)
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(.vTextGhost)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(verbatim: headword)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(.vTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .padding(.top, -6)
                meta
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.vTextSecondary)
                    .padding(.top, 4)
            }
            Text(verbatim: definition)
                .font(.system(size: 18))
                .foregroundStyle(.vTextPrimary)
            if let confusion {
                HStack(spacing: 10) {
                    Text(verbatim: "≠ \(confusion.word)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.vTextPrimary)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 32)
                        .background(.vSurfaceRaised, in: .capsule)
                    Text(verbatim: confusion.meaning)
                        .font(.system(size: 15))
                        .foregroundStyle(.vTextSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer(minLength: 0)
            Text(verbatim: "Sagace")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.vTextSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(28)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(.vSurface, in: .rect(cornerRadius: SagaceMetrics.cardRadius, style: .continuous))
        .padding(16)
        .background(.vBackground)
    }

    /// Rendu en image dans l'apparence demandée, indépendamment de celle de l'app.
    @MainActor
    public func image(colorScheme: ColorScheme, scale: CGFloat = 3) -> UIImage? {
        let renderer = ImageRenderer(content: environment(\.colorScheme, colorScheme))
        renderer.scale = scale
        return renderer.uiImage
    }
}
