import SagaceCore
import SagaceUI
import SwiftUI
import WidgetKit

/// Série (petit) : laurier, nombre de jours, anneau de l'objectif du jour.
struct SerieWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SerieWidget", provider: SerieProvider()) { entry in
            SerieWidgetView(entry: entry)
                .environment(\.locale, AppLanguagePreference.saved().locale)
        }
        .configurationDisplayName("Série")
        .description("Votre série de jours et l'objectif du jour.")
        .supportedFamilies([.systemSmall])
    }
}

struct SerieEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let progress: Double
    let hasSnapshot: Bool
}

struct SerieProvider: TimelineProvider {
    func placeholder(in context: Context) -> SerieEntry {
        SerieEntry(date: .now, streak: 0, progress: 0, hasSnapshot: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SerieEntry) -> Void) {
        completion(entry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SerieEntry>) -> Void) {
        // Au nouveau jour, l'anneau repart de zéro et la série peut se perdre : une entrée de plus à minuit.
        let day = SagaceDay()
        let midnight = day.calendar.startOfDay(for: day.calendar.date(byAdding: .day, value: 1, to: .now) ?? .now)
        completion(Timeline(entries: [entry(at: .now), entry(at: midnight)], policy: .atEnd))
    }

    private func entry(at date: Date) -> SerieEntry {
        guard let snapshot = WidgetStore.shared?.readSnapshot() else {
            return SerieEntry(date: date, streak: 0, progress: 0, hasSnapshot: false)
        }
        let day = SagaceDay()
        let sorted = snapshot.sortedToday(at: date, day: day)
        return SerieEntry(
            date: date, streak: snapshot.streak(at: date, day: day),
            progress: min(Double(sorted) / Double(max(snapshot.dailyGoal, 1)), 1), hasSnapshot: true
        )
    }
}

struct SerieWidgetView: View {
    let entry: SerieEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(Color.vSurfaceSelected, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(Color.vBlue, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .widgetAccentable()
                Image(systemName: "laurel.leading")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.vTextPrimary)
            }
            .frame(width: 70, height: 70)
            Text("Série : \(entry.streak) jours")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.vTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if !entry.hasSnapshot {
                Text("Ouvrez Sagace").font(.caption2).foregroundStyle(.vTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(WidgetLink.serie.url)
        .containerBackground(for: .widget) { Color.vSurface }
        .accessibilityElement(children: .combine)
    }
}
