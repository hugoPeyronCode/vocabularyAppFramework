import SagaceUI
import SwiftUI

/// Retour après une réponse (jeux, révisions, test de précision, mini test) : "Exact." ou "Pas tout à fait.",
/// la bonne réponse, l'explication, puis "Continuer". Rien n'avance tout seul : on lit, puis on continue.
struct AnswerFeedback: View {
    let isCorrect: Bool
    let correctAnswer: String?
    let explanation: String
    var mastered: String?
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(isCorrect ? "Exact." : "Pas tout à fait.").textStyle(.title)
            } icon: {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? Color.vCorrect : .vIncorrect)
                    .font(.system(size: 26))
            }
            if !isCorrect, let correctAnswer {
                Text("Bonne réponse : \(correctAnswer)").textStyle(.rowTitle)
            }
            if !explanation.isEmpty {
                Text(verbatim: explanation)
                    .textStyle(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let mastered {
                Label("Maîtrisé : \(mastered)", systemImage: "checkmark.seal.fill")
                    .fontStyle(.rowTitle)
                    .foregroundStyle(.vCorrect)
            }
            PrimaryButton("Continuer", haptic: .selection, action: onContinue)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
    }
}
