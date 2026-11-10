import SagaceCore
import SagaceUI
import SwiftUI

/// Explorer (EXP-01) : bibliothèque, familles, thèmes, recherche flottante.
/// Sur iPad (`09_IPAD.md`), deux colonnes : l'Explorer à gauche, la page choisie à droite.
struct ExploreView: View {
    @State var viewModel: ExploreViewModel
    @State private var path: [AppRoute] = []
    /// Deux colonnes : page affichée à droite.
    @State private var selection = AppRoute.toLearn
    @State private var layout = LayoutWidth.compact
    @FocusState private var isSearchFocused: Bool
    @Environment(ScreenFactory.self) private var factory
    @Environment(AppRouter.self) private var router

    private let columns = [GridItem(.flexible(), spacing: SagaceMetrics.gutter), GridItem(.flexible(), spacing: SagaceMetrics.gutter)]

    private var isSplit: Bool { layout.isRegular }

    var body: some View {
        Group {
            if isSplit {
                SheetContainer("Explorer", systemImage: "square.grid.2x2") {
                    HStack(spacing: 0) {
                        sidebar
                            .frame(width: SagaceMetrics.sidebarWidth)
                        Rectangle()
                            .fill(.vSeparator)
                            .frame(width: 1)
                            .ignoresSafeArea(.container, edges: .bottom)
                        detail
                    }
                }
            } else {
                NavigationStack(path: $path) {
                    SheetContainer("Explorer", systemImage: "square.grid.2x2") {
                        sidebar
                    }
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: AppRoute.self) { route in
                        factory.destination(route)
                    }
                }
            }
        }
        .readsLayoutWidth($layout)
        .stackedPaywall(router)
        .onAppear { viewModel.load() }
        .onChange(of: path) { _, path in if path.isEmpty { viewModel.load() } }
        .onChange(of: selection) { viewModel.load() }
    }

    /// L'Explorer de l'iPhone ; colonne de gauche sur iPad.
    private var sidebar: some View {
        ScrollView {
            if viewModel.isSearching { searchResults } else { hub }
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .bottom) {
            SearchField("Chercher un mot", text: $viewModel.query, isFocused: $isSearchFocused)
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.bottom, 8)
        }
    }

    /// Colonne de droite : la page choisie, puis les fiches qu'on y ouvre.
    private var detail: some View {
        NavigationStack(path: $path) {
            Group {
                factory.destination(selection)
                    .environment(\.isSplitDetailRoot, true)
            }
            .navigationDestination(for: AppRoute.self) { route in
                factory.destination(route)
            }
        }
        .id(selection)
    }

    /// Ouvre une page : empilée sur iPhone, à droite sur iPad.
    private func open(_ route: AppRoute) {
        if isSplit {
            if case .fiche = route {
                path = [route]
            } else {
                selection = route
                path = []
            }
        } else {
            path.append(route)
        }
    }

    private func isSelected(_ route: AppRoute) -> Bool {
        isSplit && selection == route
    }

    // MARK: Hub

    private var hub: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack {
                Spacer()
                Button {
                    router.requirePremium(.proBanner, isPremium: viewModel.isPremium) { open(.editFollows) }
                } label: {
                    Text("Modifier").fontStyle(.button).foregroundStyle(.vTextPrimary)
                        .padding(.horizontal, 16).frame(minHeight: 40)
                        .background(isSelected(.editFollows) ? Color.vSurfaceSelected : .vSurfaceRaised, in: .capsule)
                }
                .buttonStyle(PressScaleButtonStyle())
            }
            section("Bibliothèque") {
                LazyVGrid(columns: columns, spacing: SagaceMetrics.gutter) {
                    tile(Text("À retenir"), systemImage: "bookmark", detail: Text("\(viewModel.counts.toLearn)"), route: .toLearn)
                    tile(Text("Maîtrisés"), systemImage: "checkmark.seal", detail: Text("\(viewModel.counts.mastered)"), route: .mastered)
                    tile(Text("Collections"), systemImage: "folder", detail: Text("\(viewModel.counts.collections)"), route: .collections)
                    tile(Text("Mes mots"), systemImage: "pencil.line", detail: Text("\(viewModel.counts.ownWords)"), route: .ownWords)
                    tile(Text("Historique"), systemImage: "clock.arrow.circlepath", route: .history)
                    tile(Text("Signalés"), systemImage: "flag", detail: Text("\(viewModel.counts.reports)"), route: .reports)
                }
            }
            section("Familles") {
                LazyVGrid(columns: columns, spacing: SagaceMetrics.gutter) {
                    ForEach(viewModel.families) { family in
                        tile(Text(verbatim: family.name), systemImage: family.id.symbol,
                             detail: Text("\(viewModel.ficheCount(for: family.id)) fiches"),
                             badge: badge(followed: viewModel.followedFamilies.contains(family.id)),
                             route: .topic(.family(family.id)))
                    }
                }
            }
            section("Thèmes") {
                LazyVGrid(columns: columns, spacing: SagaceMetrics.gutter) {
                    ForEach(viewModel.themes) { theme in
                        tile(Text(verbatim: theme.name), systemImage: ThemeSymbol.symbol(for: theme.id),
                             detail: Text("\(viewModel.ficheCount(forTheme: theme.id)) fiches"),
                             badge: badge(followed: viewModel.followedThemes.contains(theme.id)),
                             route: .topic(.theme(theme.id)))
                    }
                }
            }
        }
        .padding(.horizontal, SagaceMetrics.pageMargin)
        .padding(.bottom, 16)
    }

    private func tile(_ title: Text, systemImage: String, detail: Text? = nil, badge: Tile.Badge = .none, route: AppRoute) -> some View {
        Tile(title, systemImage: systemImage, detail: detail, badge: badge, isSelected: isSelected(route)) { open(route) }
    }

    private func badge(followed: Bool) -> Tile.Badge {
        followed ? .followed : (viewModel.isPremium ? .none : .locked)
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).textStyle(.title).accessibilityAddTraits(.isHeader)
            content()
        }
    }

    // MARK: Recherche (EXP-03)

    @ViewBuilder
    private var searchResults: some View {
        if viewModel.results.isEmpty {
            VStack(spacing: 16) {
                Text("Aucune fiche pour « \(viewModel.query) ».")
                    .textStyle(.definition)
                    .multilineTextAlignment(.center)
                if viewModel.suggestionSent {
                    Label("Merci, on étudie ce mot.", systemImage: "checkmark.circle.fill").textStyle(.body)
                } else {
                    SecondaryButton("Proposer ce mot ?", systemImage: "plus.bubble", haptic: nil) { viewModel.suggestQuery() }
                }
            }
            .padding(SagaceMetrics.pageMargin)
            .padding(.top, 24)
        } else {
            LazyVStack(spacing: SagaceMetrics.rowSpacing) {
                ForEach(viewModel.results) { fiche in
                    Button { open(.fiche(fiche.id)) } label: {
                        FicheRow(fiche: fiche, status: nil)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
        }
    }
}

/// Ligne de fiche (EXP-02, bibliothèque, recherche) : mot, définition courte, statut ou détail à droite.
struct FicheRow: View {
    let fiche: Fiche
    let status: FicheStatus?
    var detail: Text?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: fiche.headword).textStyle(.rowTitle)
                Text(verbatim: fiche.shortDefinition).textStyle(.body).lineLimit(2)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            if let detail {
                detail.textStyle(.meta)
            } else if let status, status != .new {
                Text(status.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.vTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.vSurface, in: .capsule)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.vTextSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
        .contentShape(.rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
