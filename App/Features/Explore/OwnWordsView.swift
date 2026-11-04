import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftUI

/// Mes mots (LIB-04) : liste et formulaire Mot · Définition · Nature · Genre si nom.
@MainActor @Observable
final class OwnWordsViewModel {
    /// Natures proposées ; "Expression" correspond à `locution`.
    static let natures: [PartOfSpeech] = [.nom, .verbe, .adjectif, .adverbe, .locution]

    private(set) var words: [OwnWord] = []
    var headword = ""
    var definition = ""
    var partOfSpeech: PartOfSpeech = .nom
    var gender: Gender = .masculin
    private(set) var showsEmptyError = false

    private let library: any LibraryStoring
    private let haptics: any HapticPlaying

    init(library: any LibraryStoring, haptics: any HapticPlaying) {
        self.library = library; self.haptics = haptics
    }

    func load() {
        words = library.ownWords()
    }

    func add() {
        do {
            try library.addOwnWord(headword: headword, definition: definition, partOfSpeech: partOfSpeech, gender: gender)
            headword = ""
            definition = ""
            showsEmptyError = false
            haptics.play(.success)
            load()
        } catch {
            showsEmptyError = true
            haptics.play(.error)
        }
    }

    func delete(_ word: OwnWord) {
        library.delete(word)
        haptics.play(.heavy)
        load()
    }
}

extension PartOfSpeech {
    var formLabel: LocalizedStringKey {
        switch self {
        case .nom: "Nom"
        case .verbe: "Verbe"
        case .adjectif: "Adjectif"
        case .adverbe: "Adverbe"
        case .locution, .preposition: "Expression"
        }
    }
}

struct OwnWordsView: View {
    @State var viewModel: OwnWordsViewModel

    var body: some View {
        SheetPage("Mes mots") {
            ScrollView {
                VStack(alignment: .leading, spacing: SagaceMetrics.rowSpacing) {
                    if viewModel.words.isEmpty {
                        EmptyState(systemImage: "pencil.line", text: "Ajoutez un mot qui vous pose problème.")
                    }
                    form
                    ForEach(viewModel.words) { word in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: word.headword).textStyle(.rowTitle)
                                Text(word.partOfSpeech.formLabel).textStyle(.meta)
                                if !word.definition.isEmpty {
                                    Text(verbatim: word.definition).textStyle(.body)
                                }
                            }
                            Spacer()
                            CircleButton(systemImage: "trash", accessibilityLabel: "Supprimer", size: 36, haptic: nil) { viewModel.delete(word) }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.bottom, 24)
            }
        }
        .onAppear { viewModel.load() }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 10) {
            field("Mot", text: $viewModel.headword)
            if viewModel.showsEmptyError {
                Text("Au moins un caractère.").font(.footnote).foregroundStyle(.vIncorrect)
            }
            field("Définition", text: $viewModel.definition, axis: .vertical)
            FlowLayout {
                ForEach(OwnWordsViewModel.natures, id: \.self) { nature in
                    Chip(nature.formLabel, isActive: viewModel.partOfSpeech == nature) { viewModel.partOfSpeech = nature }
                }
            }
            if viewModel.partOfSpeech == .nom {
                HStack(spacing: 8) {
                    Chip("Masculin", isActive: viewModel.gender == .masculin) { viewModel.gender = .masculin }
                    Chip("Féminin", isActive: viewModel.gender == .feminin) { viewModel.gender = .feminin }
                }
            }
            PrimaryButton("Ajouter", systemImage: "plus", haptic: nil) { viewModel.add() }
                .padding(.top, 4)
        }
        .padding(.bottom, 12)
    }

    private func field(_ prompt: LocalizedStringKey, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        TextField(prompt, text: text, axis: axis)
            .fontStyle(.rowTitle)
            .foregroundStyle(.vTextPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
    }
}
