import SagaceCore
import SagaceUI
import SwiftUI

/// Barre du haut du feed : couronne (gratuit), chip série, Explorer, avatar.
struct FeedTopBar: View {
    let streak: Int
    let isPremium: Bool
    let initial: String?
    let onCrown: () -> Void
    let onStreak: () -> Void
    let onExplore: () -> Void
    let onProfile: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if !isPremium {
                CircleButton(systemImage: "crown", accessibilityLabel: "Sagace Premium", kind: .accent, isActive: true, action: onCrown)
            }
            Chip("\(streak)", systemImage: "laurel.leading", action: onStreak)
                .accessibilityLabel(Text("Série : \(streak) jours"))
            Spacer()
            CircleButton(systemImage: "square.grid.2x2", accessibilityLabel: "Explorer", isActive: true, action: onExplore)
            Button(action: onProfile) {
                Group {
                    if let initial {
                        Text(verbatim: initial).font(.system(size: 18, weight: .bold))
                    } else {
                        Image(systemName: "person.fill").font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundStyle(.vOnAccent)
                .frame(width: SagaceMetrics.circleButtonSmall, height: SagaceMetrics.circleButtonSmall)
                .background(.vAvatar, in: .circle)
            }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityLabel(Text("Profil"))
        }
        .padding(.horizontal, SagaceMetrics.pageMargin)
        .padding(.vertical, 8)
    }
}

/// Accès permanent aux jeux : action principale du bas du feed.
struct FeedGamesButton: View {
    let dueReviews: Int
    let onGames: () -> Void

    var body: some View {
        Button(action: onGames) {
            HStack(spacing: 16) {
                Spacer(minLength: 0)
                Label("Jeux", systemImage: "gamecontroller.fill")
                    .font(.title3.weight(.bold))
                if dueReviews > 0 {
                    Text("\(dueReviews)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.vBlue, in: .capsule)
                        .accessibilityHidden(true)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.vOnInverse)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(.vInverse, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityIdentifier("feed.games")
        .accessibilityValue(dueReviews > 0 ? Text("\(dueReviews) révisions dues") : Text(verbatim: ""))
        .padding(.horizontal, SagaceMetrics.pageMargin)
        .padding(.vertical, 8)
    }
}

/// Frise des jours (lundi à dimanche) avec l'anneau de l'objectif.
struct DayStrip: View {
    let week: [FeedViewModel.DayCell]
    let onSelect: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Objectif quotidien", tableName: "FeedControls")
                .font(.caption.weight(.medium))
                .foregroundStyle(.vTextSecondary)
            HStack(spacing: 4) {
                ForEach(week) { cell in
                    Button { onSelect(cell.day) } label: { cellView(cell) }
                        .buttonStyle(PressScaleButtonStyle())
                        .disabled(cell.isFuture)
                        .accessibilityIdentifier(cell.isToday ? "feed.day.today" : "feed.day.other")
                        .accessibilityHint(Text("Voir les mots classés ce jour-là", tableName: "FeedControls"))
                }
            }
        }
        .padding(.horizontal, SagaceMetrics.pageMargin)
        .padding(.bottom, 2)
    }

    private func cellView(_ cell: FeedViewModel.DayCell) -> some View {
        VStack(spacing: 2) {
            Text(cell.day, format: .dateTime.weekday(.abbreviated))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.vTextSecondary)
            ZStack {
                ProgressRing(progress: cell.progress, lineWidth: 2)
                    .opacity(cell.isFuture ? 0.25 : 1)
                Text(cell.day, format: .dateTime.day())
                    .font(.system(size: 13, weight: cell.isToday ? .bold : .medium))
                    .foregroundStyle(cell.isFuture ? Color.vTextSecondary : .vTextPrimary)
            }
            .frame(width: 28, height: 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(cell.isToday ? Color.vSurfaceSelected : .clear, in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text("\(Int(min(cell.progress, 1) * 100)) %"))
    }
}
