import SagaceCore
import SagaceUI
import SwiftUI
import TipKit

/// Carte fiche du feed (FEED-01), centrée sur le mot à la Vocabulary : mot en héros, phonétique et écoute,
/// nature et définition courte. Chaque toucher dévoile un détail de plus (confusion, bon usage, exemple,
/// phrase d'auteur) ; s'il manque de hauteur, les premiers détails cèdent la place au dernier dévoilé.
/// En deux colonnes sur iPad, la fiche détaillée est à côté : la carte ne montre que le mot (`revealsDetails` faux).
struct FicheCard: View {
    let fiche: Fiche
    let isWordOfTheDay: Bool
    let details: [FeedViewModel.Detail]
    let revealed: Int
    var revealsDetails = true
    let sorting: Sorting?
    let isCurrent: Bool
    let onSpeak: () -> Void
    let onReveal: () -> Void
    let onInfo: () -> Void
    let onShare: () -> Void
    let onSort: (Sorting) -> Void
    private let sortTip = SortTip()
    private let infoTip = InfoTip()
    @Environment(\.layoutWidth) private var layoutWidth

    private var shownCount: Int { revealsDetails ? revealed : 0 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                actionsMenu
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            ViewThatFits(in: .vertical) {
                ForEach(0...shownCount, id: \.self) { dropped in
                    content(shown: Array(details.prefix(shownCount).dropFirst(dropped)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(.rect)
            .onTapGesture { if revealsDetails { onReveal() } }
            .accessibilityActions {
                if revealsDetails { Button("En savoir plus", action: onReveal) }
            }
            if revealsDetails, revealed < details.count {
                Label("Touchez pour en savoir plus", systemImage: "hand.tap")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.vTextSecondary)
                    .padding(.bottom, 10)
                    .transition(.opacity)
            }
            HStack(spacing: 10) {
                sortButton(.known, title: Text("Je connais", tableName: "FeedControls"), symbol: "checkmark", identifier: "feed.known")
                sortButton(.toLearn, title: Text("À retenir"), symbol: "bookmark", identifier: "feed.learn")
            }
            .popoverTip(isCurrent ? sortTip : nil, arrowEdge: .bottom)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBackground()
        .animation(SagaceMotion.select, value: revealed)
    }

    private var actionsMenu: some View {
        Menu {
            Button {
                infoTip.invalidate(reason: .actionPerformed)
                onInfo()
            } label: { Label("Fiche détaillée", systemImage: "info.circle") }
            Button(action: onShare) { Label("Partager", systemImage: "square.and.arrow.up") }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.vTextSecondary)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .accessibilityLabel(Text("Options de la fiche", tableName: "FeedControls"))
        .accessibilityIdentifier("feed.card.options")
        .popoverTip(isCurrent ? infoTip : nil, arrowEdge: .top)
    }

    private func sortButton(_ value: Sorting, title: Text, symbol: String, identifier: String) -> some View {
        Button {
            sortTip.invalidate(reason: .actionPerformed)
            InfoTip.hasSorted = true
            onSort(value)
        } label: {
            ViewThatFits(in: .horizontal) {
                Label { title } icon: { Image(systemName: symbol) }.fixedSize()
                title.multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(sorting == value ? Color.vOnInverse : .vTextPrimary)
            .background(sorting == value ? Color.vInverse : .vSurfaceRaised, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(title)
        .accessibilityAddTraits(sorting == value ? .isSelected : [])
    }

    private var header: some View {
        VStack(spacing: 2) {
            if isWordOfTheDay {
                Text("Mot du jour")
                    .textStyle(.heroGhost)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Text(verbatim: fiche.headword)
                .accessibilityIdentifier("feed.headword")
                .textStyle(layoutWidth.isRegular ? .heroLarge : .hero)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.top, isWordOfTheDay ? -8 : 0)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 8) {
                // L'alphabet phonétique est illisible pour VoiceOver : le bouton fait entendre le mot.
                if fiche.hasPhonetic {
                    Text(verbatim: fiche.phonetic).accessibilityHidden(true)
                }
                CircleButton(systemImage: "speaker.wave.2", accessibilityLabel: "Écouter la prononciation", size: 32, isActive: true, action: onSpeak)
            }
            .textStyle(.meta)
            .padding(.top, 4)
            (fiche.hasGrammar ? Text("\(Text(fiche.grammarLabel).italic()) \(fiche.shortDefinition)") : Text(verbatim: fiche.shortDefinition))
                .textStyle(layoutWidth.isRegular ? .definitionLarge : .definition)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
        }
        .multilineTextAlignment(.center)
    }

    private func content(shown: [FeedViewModel.Detail]) -> some View {
        VStack(spacing: 22) {
            header
            ForEach(shown, id: \.self) { detail in
                detailView(detail)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private func detailView(_ detail: FeedViewModel.Detail) -> some View {
        switch detail {
        case .confusion(let confusion):
            VStack(spacing: 8) {
                Text("À ne pas confondre").textStyle(.metricLabel).textCase(.uppercase)
                HStack(spacing: 10) {
                    Chip(verbatim: confusion.word)
                    Text(verbatim: confusion.meaning)
                        .textStyle(.body)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        case .usage(let usage):
            VStack(alignment: .leading, spacing: 8) {
                Label { Text("On dit : \(usage.correct)") } icon: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.vCorrect)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Label { Text("On évite : \(usage.avoid)") } icon: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.vIncorrect)
                    }
                    Text(usage.verdict.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.vTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.vSurfaceRaised, in: .capsule)
                }
            }
            .fontStyle(.body)
            .foregroundStyle(.vTextPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .example(let example):
            Text(marked: example)
                .fontStyle(.body)
                .foregroundStyle(.vTextPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        case .quote(let quote):
            VStack(spacing: 6) {
                Text(verbatim: "« \(quote.text) »").italic()
                Text("\(quote.author), \(quote.work) (\(String(quote.year)))").font(.footnote)
            }
            .textStyle(.body)
            .multilineTextAlignment(.center)
        }
    }
}
