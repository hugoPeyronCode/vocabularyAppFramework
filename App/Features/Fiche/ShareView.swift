import MessageUI
import Observation
import SagaceCore
import SagaceUI
import SwiftUI
import UIKit

/// Partage d'une fiche (SHR-01) : carte image en clair ou en sombre, texte copiable.
@MainActor @Observable
final class ShareViewModel {
    let fiche: Fiche
    let familyName: String
    var appearance: ColorScheme = .light {
        didSet { renderImage() }
    }
    private(set) var image: UIImage?
    private(set) var feedback: Feedback?

    enum Feedback: Equatable { case saved, copied }

    private let haptics: any HapticPlaying

    init(fiche: Fiche, familyName: String, haptics: any HapticPlaying) {
        self.fiche = fiche; self.familyName = familyName; self.haptics = haptics
    }

    var card: ShareCard {
        ShareCard(
            familyName: familyName,
            headword: fiche.headword,
            meta: fiche.hasGrammar && fiche.hasPhonetic ? Text("\(Text(fiche.grammarLabel)) · \(fiche.phonetic)")
                : fiche.hasGrammar ? Text(fiche.grammarLabel) : Text(verbatim: fiche.phonetic),
            definition: fiche.shortDefinition,
            confusion: fiche.confusions.first.map { ShareCard.Confusion(word: $0.word, meaning: $0.meaning) }
        )
    }

    /// "éminent ≠ imminent. Éminent : … Imminent : … Via Sagace."
    var shareText: String {
        let headword = fiche.headword
        guard let confusion = fiche.confusions.first else {
            return String(localized: "\(headword.capitalizedFirst) : \(fiche.shortDefinition). Via Sagace.")
        }
        return String(localized: "\(headword) ≠ \(confusion.word). \(headword.capitalizedFirst) : \(fiche.shortDefinition). \(confusion.word.capitalizedFirst) : \(confusion.meaning). Via Sagace.")
    }

    func renderImage() {
        image = card.image(colorScheme: appearance)
    }

    func saveImage() {
        guard let image else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        haptics.play(.success)
        show(.saved)
    }

    func copyText() {
        UIPasteboard.general.string = shareText
        haptics.play(.success)
        show(.copied)
    }

    private func show(_ feedback: Feedback) {
        self.feedback = feedback
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            if self.feedback == feedback { self.feedback = nil }
        }
    }

    var canSendMessages: Bool { MFMessageComposeViewController.canSendText() }
}

struct ShareView: View {
    @State var viewModel: ShareViewModel
    @State private var isComposingMessage = false

    var body: some View {
        SheetContainer("Partager", systemImage: "square.and.arrow.up") {
            ScrollView {
                VStack(spacing: 18) {
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
                            .frame(maxHeight: 360)
                            .accessibilityLabel(Text(verbatim: viewModel.shareText))
                    }
                    HStack(spacing: 8) {
                        Chip("Clair", systemImage: "sun.max", isActive: viewModel.appearance == .light) { viewModel.appearance = .light }
                        Chip("Sombre", systemImage: "moon", isActive: viewModel.appearance == .dark) { viewModel.appearance = .dark }
                    }
                    VStack(spacing: SagaceMetrics.rowSpacing) {
                        OptionRow("Enregistrer l'image", systemImage: "square.and.arrow.down", isSelected: false, haptic: nil) {
                            viewModel.saveImage()
                        }
                        OptionRow("Copier le texte", systemImage: "doc.on.doc", isSelected: false, haptic: nil) {
                            viewModel.copyText()
                        }
                        if viewModel.canSendMessages {
                            OptionRow("Messages", systemImage: "message", isSelected: false) { isComposingMessage = true }
                        }
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        } bottomBar: {
            if let image = viewModel.image {
                ShareLink(item: Image(uiImage: image), message: Text(verbatim: viewModel.shareText),
                          preview: SharePreview(Text(verbatim: viewModel.fiche.headword), image: Image(uiImage: image))) {
                    Label("Partager…", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(CapsuleButtonStyle(.primary))
                .padding(.horizontal, 12)
            }
        }
        .toast(viewModel.feedback) { feedback in
            Toast(feedback == .saved ? Text("Image enregistrée") : Text("Texte copié"), systemImage: "checkmark")
        }
        .sheet(isPresented: $isComposingMessage) {
            MessageComposer(body: viewModel.shareText, image: viewModel.image)
        }
        .onAppear { viewModel.renderImage() }
    }
}

/// Composition d'un message avec la carte en pièce jointe.
private struct MessageComposer: UIViewControllerRepresentable {
    let body: String
    let image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = body
        if let data = image?.pngData() {
            controller.addAttachmentData(data, typeIdentifier: "public.png", filename: "sagace.png")
        }
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    @MainActor
    final class Coordinator: NSObject, @preconcurrency MFMessageComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            dismiss()
        }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
