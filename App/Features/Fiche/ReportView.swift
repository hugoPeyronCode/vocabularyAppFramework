import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftUI

/// Signaler une erreur (DET-02). File locale en attendant un endpoint (`OPEN_QUESTIONS.md` n° 8).
@MainActor @Observable
final class ReportViewModel {
    let ficheID: String
    var reason: ReportReason?
    var comment = ""
    private(set) var isSent = false

    private let library: any LibraryStoring
    private let haptics: any HapticPlaying
    private let analytics: any Analytics

    init(ficheID: String, library: any LibraryStoring, haptics: any HapticPlaying, analytics: any Analytics) {
        self.ficheID = ficheID; self.library = library; self.haptics = haptics; self.analytics = analytics
    }

    var canSend: Bool { reason != nil && !isSent }

    func send() {
        guard let reason, !isSent else { return }
        library.report(ficheID: ficheID, reason: reason, comment: comment)
        analytics.track(.errorReported(ficheID: ficheID, reason: reason))
        haptics.play(.success)
        isSent = true
    }
}

struct ReportView: View {
    @State var viewModel: ReportViewModel
    @Environment(\.dismiss) private var dismiss

    private let reasons: [(ReportReason, LocalizedStringKey)] = [
        (.definition, "Définition inexacte"), (.example, "Exemple maladroit"), (.typo, "Faute dans le texte"), (.other, "Autre"),
    ]

    var body: some View {
        SheetContainer("Signaler une erreur", systemImage: "flag") {
            ScrollView {
                VStack(spacing: SagaceMetrics.rowSpacing) {
                    ForEach(reasons, id: \.0) { reason, title in
                        OptionRow(title, isSelected: viewModel.reason == reason) { viewModel.reason = reason }
                    }
                    TextField("Précisez si vous le souhaitez", text: $viewModel.comment, axis: .vertical)
                        .lineLimit(3...6)
                        .fontStyle(.definition)
                        .foregroundStyle(.vTextPrimary)
                        .padding(16)
                        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                        .padding(.top, 6)
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        } bottomBar: {
            PrimaryButton("Envoyer", haptic: nil) { viewModel.send() }
                .disabled(!viewModel.canSend)
                .padding(.horizontal, 12)
        }
        .toast(viewModel.isSent ? true : nil) { _ in
            Toast(Text("Merci, on corrige sous 7 jours."), systemImage: "checkmark.seal")
        }
        .onChange(of: viewModel.isSent) { _, sent in
            guard sent else { return }
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                dismiss()
            }
        }
    }
}
