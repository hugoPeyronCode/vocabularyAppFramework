import SagaceUI
import SwiftUI

/// Modale plein écran, avec un titre discret séparé de la question et une sortie toujours accessible.
struct GameContainer<Content: View>: View {
    var title: Text? = nil
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                title?
                    .textStyle(.meta)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("game.title")
                Spacer(minLength: 8)
                CircleButton(systemImage: "xmark", accessibilityLabel: "Fermer", size: 40) { dismiss() }
                    .accessibilityIdentifier("game.close")
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
            .padding(.vertical, 10)
            content()
                .readableColumn(SagaceMetrics.focusWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.vSurface.ignoresSafeArea())
        .measuresLayoutWidth()
    }
}

struct GameLoadingView: View {
    var body: some View {
        ProgressView()
            .controlSize(.regular)
            .accessibilityLabel(Text("Chargement", tableName: "GamePresentation"))
            .accessibilityIdentifier("game.loading")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
