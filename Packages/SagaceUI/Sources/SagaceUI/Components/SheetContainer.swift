import SwiftUI

/// Contenu d'une sheet flottante : poignée 36 × 5 en haut, titre centré `sheetTitle` avec icône,
/// bouton rond `xmark` optionnel, barre basse optionnelle. À présenter avec `floatingSheet`.
///
/// Sur iOS 26, le système fait flotter la sheet (bords décalés, grand rayon) : on remplace seulement son verre
/// par `surface`. Avant iOS 26, le fond système est transparent et ce conteneur dessine lui-même la sheet,
/// à 12 pt des bords et du bas avec un rayon de 44.
public struct SheetContainer<Content: View, BottomBar: View>: View {
    let title: LocalizedStringKey?
    let systemImage: String?
    let showsCloseButton: Bool
    let content: Content
    let bottomBar: BottomBar
    @Environment(\.dismiss) private var dismiss

    public init(
        _ title: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        showsCloseButton: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottomBar: () -> BottomBar
    ) {
        self.title = title; self.systemImage = systemImage; self.showsCloseButton = showsCloseButton
        self.content = content(); self.bottomBar = bottomBar()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.vSeparator)
                .frame(width: SagaceMetrics.grabberSize.width, height: SagaceMetrics.grabberSize.height)
                .padding(.top, 8)
                .accessibilityHidden(true)
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            bottomBar
                .padding(.horizontal, SagaceMetrics.sheetInset)
                .padding(.bottom, SagaceMetrics.sheetInset)
        }
        .modifier(LegacyFloatingChrome())
        .ignoresSafeArea(.container, edges: .bottom)
    }

    @ViewBuilder
    private var header: some View {
        if title != nil || showsCloseButton {
            ZStack {
                if let title {
                    Group {
                        if let systemImage {
                            Label(title, systemImage: systemImage)
                        } else {
                            Text(title)
                        }
                    }
                    .textStyle(.sheetTitle)
                    .symbolVariant(.fill)
                    .accessibilityAddTraits(.isHeader)
                }
                if showsCloseButton {
                    HStack {
                        Spacer()
                        CircleButton(systemImage: "xmark", accessibilityText: Text("Fermer", bundle: .module), size: 36) { dismiss() }
                    }
                }
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
    }
}

public extension SheetContainer where BottomBar == EmptyView {
    init(
        _ title: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        showsCloseButton: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title, systemImage: systemImage, showsCloseButton: showsCloseButton, content: content) { EmptyView() }
    }
}

/// Avant iOS 26 : la sheet est dessinée par `SheetContainer` sur un fond système transparent.
private struct LegacyFloatingChrome: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content
                .background(.vSurface, in: .rect(cornerRadius: SagaceMetrics.sheetRadius, style: .continuous))
                .clipShape(.rect(cornerRadius: SagaceMetrics.sheetRadius, style: .continuous))
                .padding([.horizontal, .bottom], SagaceMetrics.sheetInset)
        }
    }
}

public extension PresentationDetent {
    /// Hauteur par défaut d'une sheet flottante. `.large` n'est pas flottante sur iOS 26.
    static let floating = PresentationDetent.fraction(0.93)
}

public extension View {
    /// Présente `content` (en général un `SheetContainer`) en sheet flottante.
    func floatingSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        detents: Set<PresentationDetent> = [.floating],
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        sheet(item: item) { item in
            content(item).modifier(FloatingSheetPresentation(detents: detents))
        }
    }

    func floatingSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.floating],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented) {
            content().modifier(FloatingSheetPresentation(detents: detents))
        }
    }
}

private struct FloatingSheetPresentation: ViewModifier {
    let detents: Set<PresentationDetent>

    func body(content: Content) -> some View {
        content
            .modifier(FloatingSheetBackground())
            .presentationDetents(detents)
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(SagaceMetrics.sheetRadius)
    }
}

private struct FloatingSheetBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.presentationBackground(.vSurface)
        } else {
            content.presentationBackground(.clear)
        }
    }
}
