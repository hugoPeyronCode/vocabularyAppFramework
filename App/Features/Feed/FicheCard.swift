import SagaceCore
import SagaceUI
import SwiftUI

/// Carte fiche du feed (FEED-01) : famille en fantôme, mot en héros, nature et phonétique,
/// définition courte, confusion, usage, phrase d'auteur, pilule "S'entraîner".
/// Les blocs les moins essentiels disparaissent si la carte manque de hauteur.
struct FicheCard: View {
    let fiche: Fiche
    let familyName: String
    let onPractice: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .vertical) {
                content(showsUsage: true, showsQuote: true)
                content(showsUsage: true, showsQuote: false)
                content(showsUsage: false, showsQuote: false)
                header
            }
            .frame(maxHeight: .infinity, alignment: .center)
            Button(action: onPractice) {
                Label("S'entraîner", systemImage: "play.fill")
                    .fontStyle(.button)
                    .foregroundStyle(.vOnInverse)
                    .padding(.horizontal, 22)
                    .frame(minHeight: 48)
                    .background(.vInverse, in: .capsule)
            }
            .buttonStyle(PressScaleButtonStyle())
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBackground()
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text(verbatim: familyName)
                .textStyle(.heroGhost)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityHidden(true)
            Text(verbatim: fiche.headword)
                .textStyle(.hero)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.top, -8)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 8) {
                Text(fiche.grammarLabel)
                Text(verbatim: fiche.phonetic)
            }
            .textStyle(.meta)
            .padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
    }

    private func content(showsUsage: Bool, showsQuote: Bool) -> some View {
        VStack(spacing: 18) {
            header
            Text(verbatim: fiche.shortDefinition)
                .textStyle(.definition)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let confusion = fiche.confusions.first {
                confusionBlock(confusion)
            }
            if showsUsage, let usage = fiche.usage {
                usageBlock(usage)
            }
            if showsQuote, let quote = fiche.authorQuote {
                quoteBlock(quote)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private func confusionBlock(_ confusion: Confusion) -> some View {
        VStack(spacing: 8) {
            Text("À ne pas confondre")
                .textStyle(.metricLabel)
                .textCase(.uppercase)
            HStack(spacing: 10) {
                Chip(verbatim: confusion.word)
                Text(verbatim: confusion.meaning)
                    .textStyle(.body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func usageBlock(_ usage: UsageNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("On dit : \(usage.correct)")
            } icon: {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.vCorrect)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label {
                    Text("On évite : \(usage.avoid)")
                } icon: {
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
    }

    private func quoteBlock(_ quote: AuthorQuote) -> some View {
        VStack(spacing: 6) {
            Text(verbatim: "« \(quote.text) »")
                .italic()
            Text("\(quote.author), \(quote.work) (\(String(quote.year)))")
                .font(.footnote)
        }
        .textStyle(.body)
        .multilineTextAlignment(.center)
    }
}
