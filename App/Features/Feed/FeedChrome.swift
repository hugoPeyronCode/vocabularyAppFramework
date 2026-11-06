import SagaceCore
import SagaceUI
import SwiftUI
import TipKit

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

/// Barre d'actions : fiche détaillée, partager, Jeux (avec les révisions dues), Je savais, À retenir.
struct FeedActionBar: View {
    let sorting: Sorting?
    let canSort: Bool
    let hasFiche: Bool
    let dueReviews: Int
    /// Masqué quand la fiche détaillée est déjà à côté de la carte (iPad paysage).
    var showsInfo = true
    let sortTip: SortTip
    let infoTip: InfoTip
    let onInfo: () -> Void
    let onShare: () -> Void
    let onGames: () -> Void
    let onSort: (Sorting) -> Void

    var body: some View {
        HStack(spacing: 10) {
            if showsInfo {
                CircleButton(systemImage: "info", accessibilityLabel: "Fiche détaillée", size: SagaceMetrics.circleButtonLarge, action: onInfo)
                    .popoverTip(infoTip, arrowEdge: .bottom)
                    .disabled(!hasFiche)
            }
            CircleButton(systemImage: "square.and.arrow.up", accessibilityLabel: "Partager", size: SagaceMetrics.circleButtonLarge, action: onShare)
                .disabled(!hasFiche)
            Spacer(minLength: 0)
            gamesButton
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                CircleButton(systemImage: "checkmark", accessibilityLabel: "Je savais", size: SagaceMetrics.circleButtonLarge,
                             isActive: sorting == .known, haptic: nil) { onSort(.known) }
                CircleButton(systemImage: "bookmark", accessibilityLabel: "À retenir", size: SagaceMetrics.circleButtonLarge,
                             isActive: sorting == .toLearn, haptic: nil) { onSort(.toLearn) }
            }
            .popoverTip(sortTip, arrowEdge: .bottom)
            .disabled(!canSort)
            .opacity(canSort ? 1 : 0.4)
        }
        .padding(.horizontal, SagaceMetrics.pageMargin)
        .padding(.vertical, 12)
    }

    /// L'espace Jeux : jeux, défis, test, et les révisions dues (badge).
    private var gamesButton: some View {
        Button(action: onGames) {
            // Le libellé tombe si la barre manque de place (grands corps de texte) : il reste l'icône.
            ViewThatFits(in: .horizontal) {
                Label("Jeux", systemImage: "gamecontroller.fill").fixedSize()
                Image(systemName: "gamecontroller.fill")
            }
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(.vOnInverse)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(.vInverse, in: .capsule)
                .overlay(alignment: .topTrailing) {
                    if dueReviews > 0 {
                        Text("\(dueReviews)")
                            .font(.system(size: 12, weight: .bold).monospacedDigit())
                            .foregroundStyle(.vOnAccent)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(.vBlue, in: .capsule)
                            .offset(x: 6, y: -6)
                    }
                }
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityValue(dueReviews > 0 ? Text("\(dueReviews) révisions dues") : Text(verbatim: ""))
    }
}

/// Frise des jours (lundi à dimanche) avec l'anneau de l'objectif.
struct DayStrip: View {
    let week: [FeedViewModel.DayCell]
    let hoursToNextBatch: Int?
    let onSelect: (Date) -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(week) { cell in
                    Button { onSelect(cell.day) } label: { cellView(cell) }
                        .buttonStyle(PressScaleButtonStyle())
                        .disabled(cell.isFuture)
                }
            }
            if let hours = hoursToNextBatch {
                Text("Prochain lot dans \(hours) h")
                    .textStyle(.meta)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func cellView(_ cell: FeedViewModel.DayCell) -> some View {
        VStack(spacing: 4) {
            Text(cell.day, format: .dateTime.weekday(.abbreviated))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.vTextSecondary)
            Text(cell.day, format: .dateTime.day())
                .fontStyle(.rowTitle)
                .foregroundStyle(cell.isFuture ? Color.vTextSecondary : .vTextPrimary)
            ProgressRing(progress: cell.progress)
                .frame(width: 18, height: 18)
                .opacity(cell.isFuture ? 0.4 : 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(cell.isToday ? Color.vSurfaceSelected : .clear, in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text("\(Int(min(cell.progress, 1) * 100)) %"))
    }
}
