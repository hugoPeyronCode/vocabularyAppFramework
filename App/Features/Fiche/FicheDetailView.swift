import SagaceCore
import SagaceUI
import SwiftUI

/// Fiche détaillée (DET-01) : sections qui n'apparaissent que si la fiche les remplit.
struct FicheDetailView: View {
    @State var viewModel: FicheDetailViewModel
    @Environment(ScreenFactory.self) private var factory
    @State private var modal: Modal?

    enum Modal: String, Identifiable {
        case share, collection, report
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                ForEach(viewModel.sections, id: \.self) { section in
                    sectionView(section)
                }
                if viewModel.showsBetaReview { betaReview }
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .background(.vSurface)
        .onAppear { viewModel.onAppear() }
        .floatingSheet(item: $modal) { modal in
            switch modal {
            case .share: factory.share(viewModel.fiche.id)
            case .collection: factory.addToCollection(viewModel.fiche.id)
            case .report: factory.report(viewModel.fiche.id)
            }
        }
    }

    // MARK: En-tête

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: viewModel.familyName)
                .textStyle(.heroGhost)
                .accessibilityHidden(true)
            Text(verbatim: viewModel.fiche.headword)
                .textStyle(.hero)
                .padding(.top, -12)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 10) {
                if viewModel.fiche.hasPhonetic {
                    Text(verbatim: viewModel.fiche.phonetic).textStyle(.meta).accessibilityHidden(true)
                }
                CircleButton(systemImage: "speaker.wave.2", accessibilityLabel: "Écouter la prononciation", size: 36, isActive: true) {
                    viewModel.speak()
                }
                if viewModel.fiche.hasGrammar {
                    Text(viewModel.fiche.grammarLabel).textStyle(.meta)
                }
                Text(viewModel.fiche.register.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.vTextSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.vSurfaceRaised, in: .capsule)
            }
        }
    }

    // MARK: Sections

    @ViewBuilder
    private func sectionView(_ section: FicheSection) -> some View {
        let fiche = viewModel.fiche
        switch section {
        case .sens:
            DetailSection("Sens") { Text(verbatim: fiche.definition).textStyle(.definition) }
        case .confusions:
            DetailSection("À ne pas confondre") {
                ForEach(fiche.confusions, id: \.word) { confusion in
                    VStack(alignment: .leading, spacing: 6) {
                        wordChip(confusion.word)
                        Text(verbatim: confusion.meaning).textStyle(.definition)
                        Text(verbatim: confusion.example).textStyle(.body).italic()
                    }
                }
            }
        case .usage:
            if let usage = fiche.usage {
                DetailSection("Bon usage") {
                    Label { Text("On dit : \(usage.correct)") } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.vCorrect)
                    }
                    .fontStyle(.definition)
                    Label { Text("On évite : \(usage.avoid)") } icon: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.vIncorrect)
                    }
                    .fontStyle(.definition)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(usage.verdict.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.vTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.vSurfaceRaised, in: .capsule)
                        Text(verbatim: usage.explanation).textStyle(.body)
                    }
                }
                .foregroundStyle(.vTextPrimary)
            }
        case .nuance:
            DetailSection("Nuance") { Text(verbatim: fiche.nuance ?? "").textStyle(.definition) }
        case .examples:
            DetailSection("Exemples") {
                ForEach(fiche.examples, id: \.self) { example in
                    Text(marked: example).fontStyle(.definition).foregroundStyle(.vTextPrimary)
                }
            }
        case .authorQuote:
            if let quote = fiche.authorQuote {
                DetailSection("Chez les auteurs") {
                    Text(verbatim: "« \(quote.text) »").textStyle(.definition).italic()
                    if let url = URL(string: quote.url) {
                        ExternalLink(url: url) {
                            Label("\(quote.author), \(quote.work) (\(String(quote.year)))", systemImage: "book")
                                .textStyle(.body)
                        }
                    }
                }
            }
        case .synonyms:
            DetailSection("Synonymes") {
                FlowLayout { ForEach(fiche.synonyms, id: \.self) { wordChip($0) } }
            }
        case .etymology:
            DetailSection("Étymologie") { Text(verbatim: fiche.etymology ?? "").textStyle(.body) }
        case .sources:
            DetailSection("Sources") {
                ForEach(fiche.sources, id: \.name) { source in
                    if let url = URL(string: source.url), source.url.hasPrefix("http") {
                        ExternalLink(url: url) {
                            Label { Text(verbatim: source.name) } icon: { Image(systemName: "link") }
                                .textStyle(.body)
                        }
                    } else {
                        Text(verbatim: source.name).textStyle(.body)
                    }
                }
                Button { modal = .report } label: {
                    Label("Signaler une erreur", systemImage: "flag")
                        .fontStyle(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.vTextPrimary)
                }
                .padding(.top, 6)
            }
        }
    }

    /// Bêta TestFlight (`05_CONTENT.md` 3.7) : verdict du testeur sur la fiche.
    private var betaReview: some View {
        DetailSection("Relecture bêta") {
            HStack(spacing: 10) {
                Button { viewModel.confirm() } label: {
                    Label(viewModel.isConfirmed ? "Jugée juste" : "Juste", systemImage: viewModel.isConfirmed ? "checkmark.circle.fill" : "checkmark")
                }
                .buttonStyle(CapsuleButtonStyle(.secondary))
                .disabled(viewModel.isConfirmed)
                SecondaryButton("À corriger", systemImage: "pencil") { modal = .report }
            }
        }
    }

    /// Mot cliquable s'il a sa propre fiche.
    @ViewBuilder
    private func wordChip(_ word: String) -> some View {
        if let id = viewModel.ficheID(for: word) {
            NavigationLink(value: AppRoute.fiche(id)) {
                Chip(verbatim: word, systemImage: "arrow.up.right")
            }
            .buttonStyle(PressScaleButtonStyle())
        } else {
            Chip(verbatim: word)
        }
    }

    // MARK: Barre basse

    private var bottomBar: some View {
        HStack(spacing: 14) {
            CircleButton(systemImage: "square.and.arrow.up", accessibilityLabel: "Partager", size: SagaceMetrics.circleButtonLarge) {
                modal = .share
            }
            CircleButton(systemImage: "folder.badge.plus", accessibilityLabel: "Ajouter à une collection", size: SagaceMetrics.circleButtonLarge) {
                modal = .collection
            }
            Spacer()
            CircleButton(systemImage: "checkmark", accessibilityLabel: "Je savais", size: SagaceMetrics.circleButtonLarge,
                         isActive: viewModel.sorting == .known, haptic: nil) { viewModel.sort(.known) }
            CircleButton(systemImage: "bookmark", accessibilityLabel: "À retenir", size: SagaceMetrics.circleButtonLarge,
                         isActive: viewModel.sorting == .toLearn, haptic: nil) { viewModel.sort(.toLearn) }
        }
        .padding(.horizontal, SagaceMetrics.pageMargin)
        .padding(.vertical, 10)
        .background(.vSurface)
    }
}

/// Section titrée en capitales de la fiche détaillée.
struct DetailSection<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .textStyle(.metricLabel)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)
            content
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
