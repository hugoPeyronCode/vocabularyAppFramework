import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftData
import SwiftUI

/// Collections (LIB-03) : liste, création, suggestions, détail.
@MainActor @Observable
final class CollectionsViewModel {
    enum SortOrder { case added, alphabetical }

    private(set) var collections: [UserCollection] = []
    var newName = ""
    private(set) var showsEmptyNameError = false
    var sortOrder: SortOrder = .added

    /// Collections proposées quand la liste est vide.
    let suggestions: [String] = [
        String(localized: "Écrire au travail"), String(localized: "Pièges des mails"), String(localized: "Bac de français"),
    ]

    private let content: ContentRepository
    private let library: any LibraryStoring
    private let haptics: any HapticPlaying

    init(content: ContentRepository, library: any LibraryStoring, haptics: any HapticPlaying) {
        self.content = content; self.library = library; self.haptics = haptics
    }

    func load() {
        collections = library.collections()
    }

    func collection(_ id: PersistentIdentifier) -> UserCollection? {
        collections.first { $0.persistentModelID == id } ?? library.collections().first { $0.persistentModelID == id }
    }

    func fiches(in collection: UserCollection) -> [Fiche] {
        let fiches = collection.ficheIDs.compactMap(content.fiche(id:))
        return sortOrder == .alphabetical ? fiches.sorted { $0.headword.localizedCompare($1.headword) == .orderedAscending } : fiches
    }

    @discardableResult
    func create(named name: String? = nil) -> Bool {
        do {
            try library.createCollection(named: name ?? newName)
            newName = ""
            showsEmptyNameError = false
            haptics.play(.success)
            load()
            return true
        } catch {
            showsEmptyNameError = true
            haptics.play(.error)
            return false
        }
    }

    @discardableResult
    func rename(_ collection: UserCollection, to name: String) -> Bool {
        do {
            try library.rename(collection, to: name)
            load()
            return true
        } catch {
            haptics.play(.error)
            return false
        }
    }

    func delete(_ collection: UserCollection) {
        library.delete(collection)
        haptics.play(.heavy)
        load()
    }

    func toggleFollow(_ collection: UserCollection) {
        library.setFollowed(collection, !collection.isFollowed)
        haptics.play(.light)
        load()
    }

    func remove(_ fiche: Fiche, from collection: UserCollection) {
        library.toggle(fiche.id, in: collection)
        load()
    }

    func toggleSortOrder() {
        sortOrder = sortOrder == .added ? .alphabetical : .added
        haptics.play(.selection)
    }
}

struct CollectionsView: View {
    @State var viewModel: CollectionsViewModel

    var body: some View {
        SheetPage("Collections") {
            ScrollView {
                VStack(alignment: .leading, spacing: SagaceMetrics.rowSpacing) {
                    if viewModel.collections.isEmpty {
                        EmptyState(systemImage: "folder", text: "Regroupez vos fiches, par exemple « Réunions » ou « Mémoire de fin d'études ».")
                    }
                    ForEach(viewModel.collections) { collection in
                        NavigationLink(value: AppRoute.collection(collection.persistentModelID)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(verbatim: collection.name).textStyle(.rowTitle)
                                    Text("\(collection.ficheIDs.count) fiches").textStyle(.body)
                                }
                                Spacer()
                                if collection.isFollowed {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.vTextPrimary)
                                        .accessibilityLabel(Text("Suivie dans le feed"))
                                }
                                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.vTextSecondary)
                            }
                            .padding(16)
                            .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                            .contentShape(.rect)
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                    NewCollectionField(name: $viewModel.newName, showsError: viewModel.showsEmptyNameError) { viewModel.create() }
                        .padding(.top, 6)
                    if viewModel.collections.isEmpty {
                        Text("Suggestions").textStyle(.metricLabel).textCase(.uppercase).padding(.top, 14)
                        ForEach(viewModel.suggestions, id: \.self) { name in
                            OptionRow(verbatim: name, systemImage: "plus.circle", isSelected: false, haptic: nil) {
                                viewModel.create(named: name)
                            }
                        }
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        }
        .onAppear { viewModel.load() }
    }
}

struct CollectionDetailView: View {
    @State var viewModel: CollectionsViewModel
    let collectionID: PersistentIdentifier
    @State private var isRenaming = false
    @State private var newName = ""
    @State private var isConfirmingDelete = false
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let collection = viewModel.collection(collectionID) {
            SheetPage(verbatim: collection.name) {
                ScrollView {
                    VStack(spacing: SagaceMetrics.rowSpacing) {
                        HStack(spacing: 10) {
                            if collection.isFollowed {
                                SecondaryButton("Suivie", systemImage: "checkmark", haptic: nil) { viewModel.toggleFollow(collection) }
                            } else {
                                PrimaryButton("Suivre dans le feed", haptic: nil) { viewModel.toggleFollow(collection) }
                            }
                            CircleButton(systemImage: "play", accessibilityLabel: "S'entraîner", size: SagaceMetrics.buttonHeight, isActive: true) {
                                router.open(.session(.fiches(collection.ficheIDs)))
                            }
                        }
                        HStack(spacing: 8) {
                            Chip(viewModel.sortOrder == .added ? "Ordre d'ajout" : "A à Z", systemImage: "arrow.up.arrow.down", haptic: nil) {
                                viewModel.toggleSortOrder()
                            }
                            Chip("Renommer", systemImage: "pencil") { newName = collection.name; isRenaming = true }
                            Chip("Supprimer", systemImage: "trash") { isConfirmingDelete = true }
                            Spacer()
                        }
                        let fiches = viewModel.fiches(in: collection)
                        if fiches.isEmpty {
                            EmptyState(systemImage: "folder", text: "Ajoutez des fiches depuis leur page détaillée.")
                        }
                        ForEach(fiches) { fiche in
                            NavigationLink(value: AppRoute.fiche(fiche.id)) {
                                FicheRow(fiche: fiche, status: nil)
                            }
                            .buttonStyle(PressScaleButtonStyle())
                            .contextMenu {
                                Button("Retirer de la collection", systemImage: "minus.circle", role: .destructive) {
                                    viewModel.remove(fiche, from: collection)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, SagaceMetrics.pageMargin)
                }
            }
            .alert("Renommer la collection", isPresented: $isRenaming) {
                TextField("Nom", text: $newName)
                Button("Annuler", role: .cancel) {}
                Button("Renommer") { viewModel.rename(collection, to: newName) }
            }
            .confirmationDialog("Supprimer cette collection ?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    viewModel.delete(collection)
                    dismiss()
                }
            }
        }
    }
}
