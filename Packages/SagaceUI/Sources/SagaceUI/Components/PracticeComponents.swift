import SwiftUI

/// Segments fins en haut de session, comme la pagination des stats (`ProgressDots`).
public struct ProgressDots: View {
    let total: Int
    let completed: Int

    public init(total: Int, completed: Int) {
        self.total = total; self.completed = completed
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Capsule()
                    .fill(index < completed ? Color.vTextPrimary : .vSurfaceSelected)
                    .frame(height: 5)
            }
        }
        .animation(SagaceMotion.select, value: completed)
        .accessibilityElement()
        .accessibilityLabel(Text("Question \(min(completed + 1, total)) sur \(total)", bundle: .module))
    }
}

/// Barre capsule `surfaceRaised` qui se vide en `accentBlue`.
public struct TimerBar: View {
    let fraction: Double

    public init(fraction: Double) {
        self.fraction = min(max(fraction, 0), 1)
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.vSurfaceRaised)
                Capsule().fill(.vBlue).frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: 8)
        .animation(.linear(duration: 0.1), value: fraction)
        .accessibilityHidden(true)
    }
}

/// Vies restantes : cœurs SF remplis.
public struct LivesView: View {
    let lives: Int
    let maximum: Int

    public init(lives: Int, maximum: Int) {
        self.lives = lives; self.maximum = maximum
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maximum, id: \.self) { index in
                Image(systemName: index < lives ? "heart.fill" : "heart")
                    .foregroundStyle(index < lives ? Color.vIncorrect : .vTextSecondary)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .font(.system(size: 18, weight: .semibold))
        .accessibilityElement()
        .accessibilityLabel(Text("\(lives) vies", bundle: .module))
    }
}

/// Carte de question sur un matériau natif, sans ombre extérieure susceptible d’être coupée.
public struct QuestionCard: View {
    let label: Text?
    let prompt: String
    let isSingleWord: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// - Parameter prompt: texte du contenu (phrase à trou, mot, définition), non localisé.
    public init(label: Text? = nil, prompt: String, isSingleWord: Bool) {
        self.label = label; self.prompt = prompt; self.isSingleWord = isSingleWord
    }

    public var body: some View {
        VStack(spacing: 6) {
            label?
                .textStyle(.heroGhost)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityHidden(true)
            Group {
                if isSingleWord {
                    Text(verbatim: prompt).font(.system(size: 34, weight: .heavy))
                } else {
                    Text(verbatim: prompt).fontStyle(.rowTitle)
                }
            }
            .foregroundStyle(.vTextPrimary)
            .accessibilityIdentifier("game.prompt")
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 180)
        .background {
            let shape = RoundedRectangle(cornerRadius: SagaceMetrics.cardRadius, style: .continuous)
            if reduceTransparency {
                shape.fill(.vSurfaceRaised)
            } else {
                shape.fill(.regularMaterial)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: SagaceMetrics.cardRadius, style: .continuous)
                .strokeBorder(.vSeparator.opacity(0.5), lineWidth: 0.5)
                .allowsHitTesting(false)
        }
    }
}

/// Score géant, sous-titre et ligne de 5 cercles d'activité (`ScoreBlock`).
public struct ScoreBlock: View {
    let score: Int
    let total: Int?
    let subtitle: Text
    let days: [Bool]

    /// - Parameter total: `nil` pour un score sans total (Sprint, Perfection).
    public init(score: Int, total: Int?, subtitle: Text, days: [Bool]) {
        self.score = score; self.total = total; self.subtitle = subtitle; self.days = days
    }

    public var body: some View {
        VStack(spacing: 10) {
            Group {
                if let total {
                    Text(verbatim: "\(score) / \(total)")
                } else {
                    Text(verbatim: "\(score)")
                }
            }
            .font(.system(size: 64, weight: .heavy).monospacedDigit())
            .foregroundStyle(.vTextPrimary)
            subtitle.textStyle(.body).multilineTextAlignment(.center)
            if !days.isEmpty {
                HStack(spacing: 10) {
                    ForEach(days.indices, id: \.self) { index in
                        Circle()
                            .fill(days[index] ? Color.vTextPrimary : .clear)
                            .overlay(Circle().strokeBorder(Color.vSeparator, lineWidth: days[index] ? 0 : 2))
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(.top, 4)
                .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
