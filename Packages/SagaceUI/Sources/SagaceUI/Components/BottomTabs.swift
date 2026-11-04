import SwiftUI

/// Barre d'onglets en pilules en bas de sheet, défilante si les onglets débordent.
/// L'onglet actif est posé sur `surfaceSelected`.
public struct BottomTabs<Tab: Hashable>: View {
    public struct Item: Identifiable {
        public let id: Tab
        public let title: LocalizedStringKey
        public let systemImage: String

        public init(_ id: Tab, title: LocalizedStringKey, systemImage: String) {
            self.id = id; self.title = title; self.systemImage = systemImage
        }
    }

    let items: [Item]
    @Binding var selection: Tab
    @Environment(\.haptics) private var haptics
    @Namespace private var pill

    public init(_ items: [Item], selection: Binding<Tab>) {
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 4) {
                    ForEach(items) { item in
                        tab(item)
                            .id(item.id)
                    }
                }
                .padding(4)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onChange(of: selection) { _, newValue in
                withAnimation(SagaceMotion.select) { proxy.scrollTo(newValue, anchor: .center) }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func tab(_ item: Item) -> some View {
        let isSelected = item.id == selection
        return Button {
            guard !isSelected else { return }
            haptics.play(.selection)
            withAnimation(SagaceMotion.select) { selection = item.id }
        } label: {
            Label(item.title, systemImage: item.systemImage)
                .symbolVariant(.fill)
                .textStyle(.tab)
                .foregroundStyle(isSelected ? Color.vTextPrimary : .vTextSecondary)
                .lineLimit(1)
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.vSurfaceSelected)
                            .matchedGeometryEffect(id: "pill", in: pill)
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
