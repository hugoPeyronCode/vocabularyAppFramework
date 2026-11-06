import SwiftUI

/// Réponse de quiz : ligne d'option de 56 pt. Bonne réponse en `correct` avec check blanc,
/// mauvais choix en `incorrect` avec croix, les autres à 40 % d'opacité (`02_DESIGN_SYSTEM.md` section 6).
public struct AnswerRow: View {
    public enum State: Equatable, Sendable {
        case idle
        case correct
        case wrong
        case dimmed
    }

    let title: Text
    let state: State
    let action: () -> Void
    @Environment(\.haptics) private var haptics

    /// - Parameter title: texte de contenu (réponse issue du pack), non localisé.
    public init(_ title: String, state: State, action: @escaping () -> Void) {
        self.title = Text(verbatim: title); self.state = state; self.action = action
    }

    /// Réponse dont le libellé est de l'interface ("Juste", "Fautif").
    public init(localized title: LocalizedStringKey, state: State, action: @escaping () -> Void) {
        self.title = Text(title); self.state = state; self.action = action
    }

    public var body: some View {
        Button {
            haptics.play(.soft)
            action()
        } label: {
            HStack(spacing: 10) {
                title
                    .fontStyle(.rowTitle)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(state == .correct || state == .wrong ? Color.vOnAccent : .vTextPrimary)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: SagaceMetrics.rowHeight, alignment: .leading)
            .background(background, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
            .opacity(state == .dimmed ? 0.4 : 1)
            .contentShape(.rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(state != .idle)
        .animation(SagaceMotion.select, value: state)
        .accessibilityValue(accessibilityValue)
    }

    private var symbol: String? {
        switch state {
        case .correct: "checkmark.circle.fill"
        case .wrong: "xmark.circle.fill"
        case .idle, .dimmed: nil
        }
    }

    private var background: Color {
        switch state {
        case .correct: .vCorrect
        case .wrong: .vIncorrect
        case .idle, .dimmed: .vSurfaceRaised
        }
    }

    private var accessibilityValue: Text {
        switch state {
        case .correct: Text("Bonne réponse", bundle: .module)
        case .wrong: Text("Mauvaise réponse", bundle: .module)
        case .idle, .dimmed: Text(verbatim: "")
        }
    }
}
