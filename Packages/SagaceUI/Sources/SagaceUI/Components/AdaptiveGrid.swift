import SwiftUI

/// Grille de tuiles : 2 colonnes sur iPhone, `regularColumns` quand la sheet ou l'écran s'élargit (iPad, `09_IPAD.md`).
public struct AdaptiveGrid<Content: View>: View {
    let regularColumns: Int
    let content: Content
    @Environment(\.layoutWidth) private var layoutWidth

    public init(regularColumns: Int = 3, @ViewBuilder content: () -> Content) {
        self.regularColumns = regularColumns
        self.content = content()
    }

    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: SagaceMetrics.gutter), count: layoutWidth.isRegular ? regularColumns : 2),
            spacing: SagaceMetrics.gutter
        ) {
            content
        }
    }
}
