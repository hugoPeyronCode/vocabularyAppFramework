import SagaceUI
import SwiftUI

/// Journée (FEED-06).
struct DayView: View {
    @State var viewModel: DayViewModel
    let onReplay: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 16) {
                        Text(viewModel.day, format: .dateTime.weekday(.wide).day().month(.wide))
                            .textStyle(.hero)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        ZStack {
                            ProgressRing(progress: viewModel.progress, lineWidth: 5)
                            Text("\(viewModel.sortedCount)/\(viewModel.dailyGoal)")
                                .font(.system(size: 13, weight: .bold).monospacedDigit())
                                .foregroundStyle(.vTextPrimary)
                        }
                        .frame(width: 56, height: 56)
                    }
                    if viewModel.rows.isEmpty {
                        Text("Aucune fiche triée ce jour-là.")
                            .textStyle(.body)
                    } else {
                        VStack(spacing: SagaceMetrics.rowSpacing) {
                            ForEach(viewModel.rows) { row in
                                rowView(row)
                            }
                        }
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        } bottomBar: {
            if !viewModel.rows.isEmpty {
                PrimaryButton("Revoir ces fiches", systemImage: "arrow.counterclockwise") {
                    dismiss()
                    onReplay(viewModel.replayIDs)
                }
                .padding(.horizontal, 12)
            }
        }
        .onAppear { viewModel.load() }
    }

    private func rowView(_ row: DayViewModel.Row) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: row.headword).textStyle(.rowTitle)
                Text(verbatim: row.shortDefinition).textStyle(.body).lineLimit(2)
            }
            Spacer()
            Image(systemName: row.sorting == .known ? "checkmark.circle.fill" : "bookmark.fill")
                .font(.system(size: 20))
                .foregroundStyle(.vTextPrimary)
                .accessibilityLabel(row.sorting == .known ? Text("Je savais") : Text("À retenir"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
