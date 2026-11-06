#if DEBUG
import SagaceCore
import SagaceUI
import SwiftUI

/// Page de démonstration de tous les composants `SagaceUI` (debug uniquement).
struct DesignSystemDemoView: View {
    @State private var viewModel = DesignSystemDemoViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollViewReader { proxy in
            content
                .onAppear {
                    if let section = viewModel.initialSection { proxy.scrollTo(section, anchor: .top) }
                }
        }
        .background(.vBackground)
        .preferredColorScheme(viewModel.appearance.colorScheme)
        .floatingSheet(isPresented: $viewModel.isShowingSheet) {
            DemoSettingsSheet(viewModel: viewModel)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header
                appearance
                section("Couleurs", id: .colors) { ColorSwatches() }
                section("Typographie", id: .type) { TypeSpecimen() }
                section("Carte du jour", id: .card) { DemoCard() }
                section("Boutons", id: .buttons) { buttons }
                section("Chips", id: .chips) { chips }
                section("Lignes d'option", id: .options) { optionRows }
                section("Sheet et onglets", id: .sheet) {
                    PrimaryButton("Ouvrir une sheet", systemImage: "rectangle.bottomhalf.inset.filled") { viewModel.showSheet() }
                }
                section("Haptiques", id: .haptics) { HapticsGrid() }
            }
            .padding(SagaceMetrics.pageMargin)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: -6) {
                Text("SagaceUI")
                    .textStyle(.heroGhost)
                Text("Design system")
                    .textStyle(.hero)
            }
            Spacer()
            CircleButton(systemImage: "xmark", accessibilityLabel: "Fermer") { dismiss() }
        }
    }

    private var appearance: some View {
        FlowLayout {
            Chip("Automatique", systemImage: "circle.lefthalf.filled", isActive: viewModel.appearance == .automatic) { viewModel.appearance = .automatic }
            Chip("Clair", systemImage: "sun.max", isActive: viewModel.appearance == .light) { viewModel.appearance = .light }
            Chip("Sombre", systemImage: "moon", isActive: viewModel.appearance == .dark) { viewModel.appearance = .dark }
        }
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            PrimaryButton("Commencer l'essai gratuit") {}
            PrimaryButton("Débloquer plus de fiches", systemImage: "crown.fill") {}
                .disabled(true)
            SecondaryButton("Plus tard") {}
            HStack(spacing: 12) {
                CircleButton(systemImage: "arrow.left", accessibilityLabel: "Retour", size: SagaceMetrics.buttonHeight) {}
                ConfirmButton("Oui, recommencer") {}
            }
            HStack(spacing: 14) {
                CircleButton(systemImage: "crown", accessibilityLabel: "Premium", kind: .accent, isActive: true) {}
                Spacer()
                CircleButton(systemImage: "info.circle", accessibilityLabel: "Fiche détaillée", size: SagaceMetrics.circleButtonLarge) {}
                CircleButton(systemImage: "square.and.arrow.up", accessibilityLabel: "Partager", size: SagaceMetrics.circleButtonLarge) {}
                CircleButton(systemImage: "checkmark", accessibilityLabel: "Je savais", size: SagaceMetrics.circleButtonLarge, isActive: viewModel.isKnown) { viewModel.toggleKnown() }
                CircleButton(systemImage: "bookmark", accessibilityLabel: "À retenir", size: SagaceMetrics.circleButtonLarge, isActive: viewModel.isBookmarked) { viewModel.toggleBookmark() }
            }
        }
    }

    private var chips: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowLayout {
                Chip("Tout", isActive: viewModel.filter == .all) { viewModel.select(.all) }
                ForEach(Level.allCases, id: \.self) { level in
                    Chip(level.title, systemImage: level.symbol, isActive: viewModel.filter == .level(level)) { viewModel.select(.level(level)) }
                }
            }
            FlowLayout {
                Chip("12", systemImage: "laurel.leading")
                Chip("imminent")
            }
        }
    }

    private var optionRows: some View {
        VStack(spacing: SagaceMetrics.rowSpacing) {
            ForEach(Level.allCases, id: \.self) { level in
                OptionRow(
                    level.title,
                    description: "Niveau \(level.rawValue) sur 5",
                    systemImage: level.symbol,
                    iconTint: level == .debutant ? level.tint : .vTextSecondary,
                    selectionStyle: .fill(background: level.selectedBackground, foreground: level.selectedForeground),
                    isSelected: viewModel.selectedLevel == level,
                    boldOnSelection: level.needsBoldText
                ) { viewModel.select(level) }
            }
            Divider().overlay(.vSeparator).padding(.vertical, 8)
            OptionRow("Annuel", description: "3 jours gratuits, puis 29,99 € par an", detail: "Le plus choisi", isSelected: viewModel.selectedPlan == .yearly) { viewModel.select(.yearly) }
            OptionRow("À vie", description: "49,99 €, une seule fois", isSelected: viewModel.selectedPlan == .lifetime) { viewModel.select(.lifetime) }
        }
    }

    private func section<Content: View>(_ title: LocalizedStringKey, id: DesignSystemDemoViewModel.Section, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .textStyle(.title)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .id(id)
    }
}

// MARK: - Couleurs

private struct ColorSwatches: View {
    private let neutrals: [(String, Color)] = [
        ("background", .vBackground), ("backgroundDeep", .vBackgroundDeep), ("surface", .vSurface),
        ("surfaceRaised", .vSurfaceRaised), ("surfaceSelected", .vSurfaceSelected), ("separator", .vSeparator),
        ("textPrimary", .vTextPrimary), ("textSecondary", .vTextSecondary), ("textGhost", .vTextGhost),
        ("inverseSurface", .vInverse),
    ]
    private let accents: [(String, Color)] = [
        ("accentBlue", .vBlue), ("accentPurple", .vPurple), ("accentPurpleSoft", .vPurpleSoft),
        ("avatar", .vAvatar), ("correct", .vCorrect), ("incorrect", .vIncorrect),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            grid(neutrals)
            grid(accents)
            HStack(spacing: 8) {
                ForEach(Level.allCases, id: \.self) { level in
                    Text(level.title)
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(level.selectedForeground)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(level.selectedBackground, in: .rect(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func grid(_ swatches: [(String, Color)]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
            ForEach(swatches, id: \.0) { name, color in
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color)
                        .frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.vSeparator))
                    Text(verbatim: name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.vTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }
}

// MARK: - Typographie

private struct TypeSpecimen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Paronymes").textStyle(.heroGhost)
            Text("éminent").textStyle(.hero)
            Text("Le mot juste, sans limite.").textStyle(.title)
            Label("Réglages", systemImage: "gearshape.fill").textStyle(.sheetTitle)
            Text("Intermédiaire").textStyle(.rowTitle)
            Text("Qui s'élève au dessus des autres par son mérite ou son rang.").textStyle(.definition)
            Text("Deux mots qui se ressemblent, deux sens différents.").textStyle(.body)
            Text("/e.mi.nɑ̃/ · 0:09").textStyle(.meta)
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Maîtrisées", systemImage: "checkmark.seal.fill").textStyle(.metricLabel)
                    Text("23").textStyle(.metricValue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Label("Précision", systemImage: "scope").textStyle(.metricLabel)
                    Text("50 %").textStyle(.metricValue)
                }
            }
            Text("Continuer").textStyle(.button)
            Text("Contenu").textStyle(.tab)
            Text("A B C").textStyle(.keypad)
        }
    }
}

// MARK: - Carte

private struct DemoCard: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Paronymes").textStyle(.heroGhost)
            Text("éminent").textStyle(.hero)
            Text("adj. · /e.mi.nɑ̃/").textStyle(.meta)
                .padding(.bottom, 12)
            Text("Qui s'élève au dessus des autres par son mérite ou son rang.")
                .textStyle(.definition)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .cardBackground()
    }
}

// MARK: - Haptiques

private struct HapticsGrid: View {
    @Environment(\.haptics) private var haptics

    private let events: [(LocalizedStringKey, HapticEvent)] = [
        ("Sélection", .selection), ("Léger", .light), ("Doux", .soft), ("Fort", .heavy),
        ("Succès", .success), ("Erreur", .error), ("Célébration", .celebration),
    ]

    var body: some View {
        FlowLayout {
            ForEach(events.indices, id: \.self) { index in
                Chip(events[index].0, systemImage: "waveform", haptic: nil) { haptics.play(events[index].1) }
            }
        }
    }
}

// MARK: - Sheet

private struct DemoSettingsSheet: View {
    @Bindable var viewModel: DesignSystemDemoViewModel

    var body: some View {
        SheetContainer("Réglages", systemImage: "gearshape") {
            ScrollView {
                VStack(alignment: .leading, spacing: SagaceMetrics.rowSpacing) {
                    switch viewModel.settingsTab {
                    case .content:
                        Text("Combien de fiches par jour ?")
                            .textStyle(.rowTitle)
                            .padding(.bottom, 4)
                        dailyGoal(3, title: "3 fiches", description: "Tranquille, 1 minute")
                        dailyGoal(5, title: "5 fiches", description: "Régulier, 3 minutes")
                        dailyGoal(10, title: "10 fiches", description: "Intensif, 6 minutes")
                    default:
                        Text("Les autres onglets arrivent au jalon M5.")
                            .textStyle(.body)
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.top, 8)
            }
        } bottomBar: {
            BottomTabs([
                .init(.content, title: "Contenu", systemImage: "text.book.closed"),
                .init(.game, title: "Jeu", systemImage: "gamecontroller"),
                .init(.effects, title: "Effets", systemImage: "sparkles"),
                .init(.notifications, title: "Notifications", systemImage: "bell"),
                .init(.account, title: "Compte", systemImage: "person.crop.circle"),
            ], selection: $viewModel.settingsTab)
        }
        .preferredColorScheme(viewModel.appearance.colorScheme)
    }

    private func dailyGoal(_ goal: Int, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        OptionRow(title, description: description, detail: goal == Rules.premiumDailyGoal ? "PRO" : nil, isSelected: viewModel.selectedDailyGoal == goal) {
            viewModel.selectDailyGoal(goal)
        }
    }
}

#Preview("Clair") {
    DesignSystemDemoView().preferredColorScheme(.light)
}

#Preview("Sombre") {
    DesignSystemDemoView().preferredColorScheme(.dark)
}
#endif
