import AppIntents
import SagaceCore
import SagaceUI
import SwiftUI
import WidgetKit

/// Révision interactive (moyen) : une question, trois réponses ; chaque réponse est expliquée, puis "Continuer".
struct RevisionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RevisionWidget", provider: RevisionProvider()) { entry in
            RevisionWidgetView(entry: entry)
        }
        .configurationDisplayName("Révision")
        .description("Répondez à vos révisions sans ouvrir l'app.")
        .supportedFamilies([.systemMedium])
    }
}

struct RevisionEntry: TimelineEntry {
    let date: Date
    /// `nil` tant que l'app n'a pas écrit de snapshot.
    let display: ReviewDisplay?
}

struct RevisionProvider: TimelineProvider {
    func placeholder(in context: Context) -> RevisionEntry {
        RevisionEntry(date: .now, display: .done(remaining: 0))
    }

    func getSnapshot(in context: Context, completion: @escaping (RevisionEntry) -> Void) {
        completion(entry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RevisionEntry>) -> Void) {
        // Les révisions deviennent dues au fil des jours : on relit le snapshot au prochain lot.
        completion(Timeline(entries: [entry(at: .now)], policy: .after(SagaceDay().nextBatch(after: .now))))
    }

    private func entry(at now: Date) -> RevisionEntry {
        let store = WidgetStore.shared
        let display = store?.readSnapshot().map { $0.reviewDisplay(store?.readInbox() ?? WidgetInbox()) }
        return RevisionEntry(date: now, display: display)
    }
}

struct RevisionWidgetView: View {
    let entry: RevisionEntry
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        Group {
            switch entry.display {
            case .question(let review): question(review)
            case let .feedback(review, chosen, isCorrect): feedback(review, chosen: chosen, isCorrect: isCorrect)
            case .done(let remaining): done(remaining)
            case nil:
                Text("Ouvrez Sagace pour préparer vos révisions.")
                    .font(.footnote)
                    .foregroundStyle(.vTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetLink.revision.url)
        .containerBackground(for: .widget) { Color.vSurface }
    }

    private func question(_ review: WidgetSnapshot.Review) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: review.title)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.vTextSecondary)
            Text(verbatim: review.prompt)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.vTextPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                ForEach(review.choices.indices, id: \.self) { index in
                    Button(intent: AnswerReviewIntent(ficheID: review.ficheID, choice: index)) {
                        Text(verbatim: review.choices[index])
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.vTextPrimary)
                }
            }
        }
    }

    private func feedback(_ review: WidgetSnapshot.Review, chosen: Int, isCorrect: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text(isCorrect ? "Exact." : "Pas tout à fait.").font(.subheadline.weight(.bold))
            } icon: {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? Color.vCorrect : .vIncorrect)
                    .widgetAccentable()
            }
            .foregroundStyle(.vTextPrimary)
            if !isCorrect, review.choices.indices.contains(review.correctIndex) {
                Text("Bonne réponse : \(review.choices[review.correctIndex])")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.vTextPrimary)
            }
            Text(verbatim: review.explanation)
                .font(.caption)
                .foregroundStyle(.vTextSecondary)
                .lineLimit(3)
            Spacer(minLength: 0)
            continueButton
        }
    }

    /// Bouton plein en couleurs ; en mode teinté ou transparent, un fond plein effacerait le libellé.
    @ViewBuilder
    private var continueButton: some View {
        let button = Button(intent: ContinueReviewIntent()) {
            Text("Continuer").font(.caption.weight(.semibold)).frame(maxWidth: .infinity)
        }
        if renderingMode == .fullColor {
            button.buttonStyle(.borderedProminent).tint(.vBlue)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    private func done(_ remaining: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(.vCorrect)
                .widgetAccentable()
            Text(remaining > 0 ? "Encore \(remaining) révisions dans l'app." : "Aucune révision due. À demain !")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.vTextPrimary)
            Text("Les révisions reviennent quand un mot « À retenir » est mûr.")
                .font(.caption)
                .foregroundStyle(.vTextSecondary)
        }
    }
}
