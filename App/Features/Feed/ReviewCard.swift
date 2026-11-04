import SagaceCore
import SagaceUI
import SwiftUI

/// Carte de révision dans le feed (FEED-02) : une question sur une fiche "À retenir" arrivée à échéance.
struct ReviewCardView: View {
    let card: FeedViewModel.ReviewCard
    let answerState: (Int) -> AnswerRow.State
    let onAnswer: (Int) -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("Révision")
                    .textStyle(.heroGhost)
                    .accessibilityAddTraits(.isHeader)
                if let days = card.daysSinceSorted {
                    Chip("Vu il y a \(days) jours", systemImage: "clock")
                }
            }
            Spacer(minLength: 0)
            Text(verbatim: card.quiz.prompt)
                .textStyle(.rowTitle)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: SagaceMetrics.rowSpacing) {
                ForEach(card.quiz.choices.indices, id: \.self) { index in
                    AnswerRow(card.quiz.choices[index], state: answerState(index)) { onAnswer(index) }
                }
            }
            feedback
                .frame(minHeight: 44)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBackground()
    }

    @ViewBuilder
    private var feedback: some View {
        switch card.outcome {
        case .promoted(_, let days):
            Text("Bien retenu. Prochaine révision dans \(days) jours.")
                .textStyle(.body)
                .multilineTextAlignment(.center)
        case .mastered:
            Text("Bien retenu.")
                .textStyle(.body)
        case .reset:
            Text(verbatim: card.quiz.explanation)
                .textStyle(.body)
                .multilineTextAlignment(.center)
        case nil:
            EmptyView()
        }
    }
}

/// Carte de fin du lot (FEED-04).
struct EndCardView: View {
    let hoursToNextBatch: Int?
    let isPremium: Bool
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.vTextPrimary)
                .accessibilityHidden(true)
            Text("C'est tout pour aujourd'hui.")
                .textStyle(.title)
                .multilineTextAlignment(.center)
            if let hours = hoursToNextBatch {
                Text("Prochain lot dans \(hours) h.")
                    .textStyle(.body)
            }
            Spacer()
            if !isPremium {
                PrimaryButton("Débloquer plus de fiches", systemImage: "crown.fill", action: onUnlock)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBackground()
    }
}
