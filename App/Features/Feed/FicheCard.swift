import SagaceCore
import SagaceUI
import SwiftUI

/// Carte fiche du feed (FEED-01), centrée sur le mot à la Vocabulary : mot en héros, phonétique et écoute,
/// nature et définition courte. Chaque toucher dévoile un détail de plus (confusion, bon usage, exemple,
/// phrase d'auteur) ; s'il manque de hauteur, les premiers détails cèdent la place au dernier dévoilé.
struct FicheCard: View {
    let fiche: Fiche
    let isWordOfTheDay: Bool
    let details: [FeedViewModel.Detail]
    let revealed: Int
    let onSpeak: () -> Void
    let onReveal: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .vertical) {
                ForEach(0...revealed, id: \.self) { dropped in
                    content(shown: Array(details.prefix(revealed).dropFirst(dropped)))
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            if revealed < details.count {
                Label("Touchez pour en savoir plus", systemImage: "hand.tap")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.vTextSecondary)
                    .padding(.bottom, 20)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBackground()
        .contentShape(.rect(cornerRadius: SagaceMetrics.cardRadius))
        .onTapGesture(perform: onReveal)
        .animation(SagaceMotion.select, value: revealed)
        .accessibilityAction(named: Text("En savoir plus"), onReveal)
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
                .textStyle(.hero)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.top, isWordOfTheDay ? -8 : 0)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 8) {
                Text(verbatim: fiche.phonetic)
                CircleButton(systemImage: "speaker.wave.2", accessibilityLabel: "Écouter", size: 32, isActive: true, action: onSpeak)
            }
            .textStyle(.meta)
            .padding(.top, 4)
            Text("\(Text(fiche.grammarLabel).italic()) \(fiche.shortDefinition)")
                .textStyle(.definition)
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
