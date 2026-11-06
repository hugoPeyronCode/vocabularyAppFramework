import SagaceUI
import SwiftUI

/// Lien vers une source externe ; hors ligne, il reste lisible mais inactif, avec la mention « hors ligne ».
struct ExternalLink<Label: View>: View {
    let url: URL
    @ViewBuilder let label: () -> Label
    @Environment(Connectivity.self) private var connectivity

    var body: some View {
        if connectivity.isOnline {
            Link(destination: url, label: label)
        } else {
            HStack(spacing: 6) {
                label()
                Text("hors ligne").font(.caption.weight(.semibold)).foregroundStyle(.vTextSecondary)
            }
            .opacity(0.6)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("Lien indisponible hors ligne"))
        }
    }
}
