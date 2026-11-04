import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftUI

/// "Modifier" d'Explorer : familles et thèmes suivis par le feed (premium).
@MainActor @Observable
final class EditFollowsViewModel {
    let families: [Topics.FamilyInfo]
    let themes: [Topics.ThemeInfo]
    private(set) var followedFamilies: Set<String> = []
    private(set) var followedThemes: Set<String> = []

    private let store: any ProgressStoring
    private let haptics: any HapticPlaying

    init(topics: Topics, store: any ProgressStoring, haptics: any HapticPlaying) {
        self.families = topics.families; self.themes = topics.themes; self.store = store; self.haptics = haptics
    }

    func load() {
        followedFamilies = Set(store.preferences.followedFamilies)
        followedThemes = Set(store.preferences.followedThemes)
    }

    func toggle(family: Family) {
        store.preferences.followedFamilies.toggleMembership(family.rawValue)
        store.save()
        load()
    }

    func toggle(theme: String) {
        store.preferences.followedThemes.toggleMembership(theme)
        store.save()
        load()
    }
}

struct EditFollowsView: View {
    @State var viewModel: EditFollowsViewModel

    var body: some View {
        SheetPage("Familles et thèmes suivis") {
            ScrollView {
                VStack(alignment: .leading, spacing: SagaceMetrics.rowSpacing) {
                    Text("Le feed ne propose que les fiches suivies. Rien de coché : toutes les fiches.")
                        .textStyle(.body)
                        .padding(.bottom, 6)
                    Text("Familles").textStyle(.metricLabel).textCase(.uppercase)
                    ForEach(viewModel.families) { family in
                        let followed = viewModel.followedFamilies.contains(family.id.rawValue)
                        OptionRow(verbatim: family.name, systemImage: followed ? "checkmark.circle.fill" : family.id.symbol,
                                  isSelected: followed, haptic: .selection) { viewModel.toggle(family: family.id) }
                    }
                    Text("Thèmes").textStyle(.metricLabel).textCase(.uppercase).padding(.top, 12)
                    ForEach(viewModel.themes) { theme in
                        let followed = viewModel.followedThemes.contains(theme.id)
                        OptionRow(verbatim: theme.name, systemImage: followed ? "checkmark.circle.fill" : ThemeSymbol.symbol(for: theme.id),
                                  isSelected: followed, haptic: .selection) { viewModel.toggle(theme: theme.id) }
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.bottom, 24)
            }
        }
        .onAppear { viewModel.load() }
    }
}
