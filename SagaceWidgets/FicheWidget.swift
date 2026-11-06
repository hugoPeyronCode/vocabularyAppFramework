import AppIntents
import SagaceCore
import SagaceUI
import SwiftUI
import WidgetKit

/// Fiche du jour : petit, moyen, grand, et écran verrouillé (rectangulaire, en ligne).
struct FicheWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "FicheWidget", intent: FicheWidgetConfiguration.self, provider: FicheProvider()) { entry in
            FicheWidgetView(entry: entry)
        }
        .configurationDisplayName("Fiche du jour")
        .description("Un mot juste, chaque jour, sur votre écran d'accueil.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
    }
}

struct FicheEntry: TimelineEntry {
    let date: Date
    let card: WidgetSnapshot.Card?
    let isWordOfTheDay: Bool
    let isSaved: Bool
    let showsQuote: Bool
    let key: String
}

struct FicheProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> FicheEntry {
        FicheEntry(date: .now, card: .placeholder, isWordOfTheDay: true, isSaved: false, showsQuote: true, key: WidgetInbox.allKey)
    }

    func snapshot(for configuration: FicheWidgetConfiguration, in context: Context) async -> FicheEntry {
        entries(for: configuration, at: .now).first ?? placeholder(in: context)
    }

    func timeline(for configuration: FicheWidgetConfiguration, in context: Context) async -> Timeline<FicheEntry> {
        Timeline(entries: entries(for: configuration, at: .now), policy: .atEnd)
    }

    private func entries(for configuration: FicheWidgetConfiguration, at now: Date) -> [FicheEntry] {
        let store = WidgetStore.shared
        guard let snapshot = store?.readSnapshot() else {
            return [FicheEntry(date: now, card: nil, isWordOfTheDay: false, isSaved: false, showsQuote: false, key: WidgetInbox.allKey)]
        }
        let inbox = store?.readInbox() ?? WidgetInbox()
        // En gratuit, les réglages du widget ne s'appliquent pas : toutes les familles, une fois par jour.
        let family = snapshot.isPremium ? configuration.famille.family : nil
        let rate = snapshot.isPremium ? configuration.rafraichissement.rate : .daily
        let key = family?.rawValue ?? WidgetInbox.allKey
        let offset = inbox.cardOffsets[key] ?? 0
        let count = max(snapshot.cards(for: family).count, 1)
        return WidgetSchedule.entryDates(rate, from: now, day: SagaceDay()).enumerated().map { index, date in
            let position = offset + index
            let card = snapshot.card(for: family, offset: position)
            return FicheEntry(
                date: date, card: card, isWordOfTheDay: family == nil && position % count == 0,
                isSaved: card.map { inbox.savedIDs.contains($0.id) } ?? false,
                showsQuote: !snapshot.isPremium || configuration.phraseAuteur, key: key
            )
        }
    }
}

struct FicheWidgetView: View {
    let entry: FicheEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let card = entry.card {
                switch family {
                case .accessoryInline:
                    Text(verbatim: card.confusion.map { "\(card.headword) ≠ \($0)" } ?? card.headword)
                case .accessoryRectangular:
                    VStack(alignment: .leading, spacing: 1) {
                        Text(verbatim: card.headword).font(.headline).widgetAccentable()
                        Text(verbatim: card.shortDefinition).font(.caption).lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                default:
                    home(card)
                }
            } else {
                Text("Ouvrez Sagace pour voir votre fiche du jour.")
                    .font(.footnote)
                    .foregroundStyle(.vTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .widgetURL(entry.card.map { WidgetLink.fiche($0.id).url })
        .containerBackground(for: .widget) { Color.vSurface }
    }

    private func home(_ card: WidgetSnapshot.Card) -> some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 6) {
            Text(entry.isWordOfTheDay ? "Mot du jour" : "Fiche")
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.vTextSecondary)
            Text(verbatim: card.headword)
                .font(.system(size: family == .systemSmall ? 22 : 28, weight: .heavy))
                .foregroundStyle(.vTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .widgetAccentable()
            if family != .systemSmall {
                Text(verbatim: "\(card.grammar) \(card.phonetic)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.vTextSecondary)
            }
            Text(verbatim: card.shortDefinition)
                .font(family == .systemSmall ? .caption : .subheadline)
                .foregroundStyle(.vTextPrimary)
                .lineLimit(family == .systemLarge ? 4 : (family == .systemSmall ? 3 : 2))
            if family != .systemSmall, let confusion = card.confusion {
                Label { Text("À ne pas confondre : \(confusion)") } icon: { Image(systemName: "arrow.left.arrow.right") }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.vTextSecondary)
                    .lineLimit(1)
            }
            if family == .systemLarge, let example = card.example {
                Text(verbatim: example)
                    .font(.footnote)
                    .foregroundStyle(.vTextPrimary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            if family == .systemLarge, entry.showsQuote, let quote = card.quote {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: "« \(quote) »").italic().lineLimit(5)
                    if let source = card.quoteSource { Text(verbatim: source).font(.caption2) }
                }
                .font(.footnote)
                .foregroundStyle(.vTextSecondary)
                .padding(.top, 6)
            }
            Spacer(minLength: 0)
            if family != .systemSmall {
                HStack(spacing: 8) {
                    Button(intent: NextFicheIntent(key: entry.key)) {
                        Label("Suivante", systemImage: "arrow.right")
                    }
                    Button(intent: SaveToLearnIntent(ficheID: card.id)) {
                        Label(entry.isSaved ? "Retenue" : "À retenir", systemImage: entry.isSaved ? "bookmark.fill" : "bookmark")
                    }
                    .disabled(entry.isSaved)
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.vTextPrimary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

extension WidgetSnapshot.Card {
    /// Aperçu masqué (`redacted`) avant le premier snapshot.
    static let placeholder = WidgetSnapshot.Card(
        id: "placeholder", headword: "Sagace", phonetic: "/sa.ɡas/", grammar: "adj.",
        shortDefinition: "Qui a de la finesse d'esprit", confusion: nil, example: nil, quote: nil, quoteSource: nil, family: Family.nuance.rawValue
    )
}
