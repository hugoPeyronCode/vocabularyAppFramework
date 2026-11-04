import SwiftUI

/// Bandeau capsule en haut d'écran ("Objectif atteint · 5 fiches · Série : 12 jours").
public struct Toast: View {
    let text: Text
    let systemImage: String

    public init(_ text: Text, systemImage: String) {
        self.text = text; self.systemImage = systemImage
    }

    public var body: some View {
        Label { text } icon: { Image(systemName: systemImage).symbolVariant(.fill) }
            .fontStyle(.meta)
            .fontWeight(.semibold)
            .foregroundStyle(.vOnInverse)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .background(.vInverse, in: .capsule)
            .accessibilityAddTraits(.isStaticText)
    }
}

public extension View {
    /// Affiche `toast` en haut tant que la valeur n'est pas `nil`.
    func toast<Value: Equatable>(_ value: Value?, @ViewBuilder content: @escaping (Value) -> Toast) -> some View {
        overlay(alignment: .top) {
            if let value {
                content(value)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(SagaceMotion.select, value: value)
    }
}
