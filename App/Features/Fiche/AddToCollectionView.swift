import Foundation
import Observation
import SagaceData
import SagaceUI
import SwiftUI

/// Ajouter une fiche à une ou plusieurs collections, ou en créer une (depuis DET-01).
@MainActor @Observable
final class AddToCollectionViewModel {
    let ficheID: String
    private(set) var collections: [UserCollection] = []
    var newName = ""
    private(set) var showsEmptyNameError = false

    private let library: any LibraryStoring
    private let haptics: any HapticPlaying

    init(ficheID: String, library: any LibraryStoring, haptics: any HapticPlaying) {
        self.ficheID = ficheID; self.library = library; self.haptics = haptics
    }

    func load() {
        collections = library.collections()
    }

    func contains(_ collection: UserCollection) -> Bool {
        collection.ficheIDs.contains(ficheID)
    }

    func toggle(_ collection: UserCollection) {
        library.toggle(ficheID, in: collection)
        load()
    }

    func create() {
        do {
            let collection = try library.createCollection(named: newName)
            library.toggle(ficheID, in: collection)
            newName = ""
            showsEmptyNameError = false
            haptics.play(.success)
            load()
        } catch {
            showsEmptyNameError = true
            haptics.play(.error)
        }
    }
}

struct AddToCollectionView: View {
    @State var viewModel: AddToCollectionViewModel

    var body: some View {
        SheetContainer("Collections", systemImage: "folder") {
            ScrollView {
                VStack(spacing: SagaceMetrics.rowSpacing) {
                    ForEach(viewModel.collections) { collection in
                        OptionRow(
                            verbatim: collection.name,
                            detail: "\(collection.ficheIDs.count) fiches",
                            systemImage: viewModel.contains(collection) ? "checkmark.circle.fill" : "circle",
                            isSelected: viewModel.contains(collection),
                            haptic: .selection
                        ) { viewModel.toggle(collection) }
                    }
                    NewCollectionField(name: $viewModel.newName, showsError: viewModel.showsEmptyNameError) {
                        viewModel.create()
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        }
        .onAppear { viewModel.load() }
    }
}

/// Champ "Nouvelle collection" + bouton Créer, avec l'erreur "Au moins un caractère."
struct NewCollectionField: View {
    @Binding var name: String
    let showsError: Bool
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                TextField("Nouvelle collection", text: $name)
                    .fontStyle(.rowTitle)
                    .foregroundStyle(.vTextPrimary)
                    .submitLabel(.done)
                    .onSubmit(onCreate)
                CircleButton(systemImage: "plus", accessibilityLabel: "Créer une collection", size: 40, haptic: nil, action: onCreate)
            }
            .padding(.leading, 18)
            .padding(.trailing, 8)
            .frame(minHeight: SagaceMetrics.rowHeight)
            .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
            if showsError {
                Text("Au moins un caractère.")
                    .font(.footnote)
                    .foregroundStyle(.vIncorrect)
            }
        }
    }
}
