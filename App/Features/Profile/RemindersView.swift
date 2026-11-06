import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftData
import SwiftUI

/// Rappels (REM-01) : liste et édition. Gratuit : un rappel ; premium : illimité.
@MainActor @Observable
final class RemindersViewModel {
    private(set) var reminders: [Reminder] = []
    private(set) var editing: Reminder?
    let families: [Topics.FamilyInfo]
    private(set) var collectionNames: [String] = []

    /// Sons de notification disponibles (fichiers du bundle, plus le son système).
    let sounds = ["default", "positive", "classical"]

    private let profile: any ProfileStoring
    private let library: any LibraryStoring
    private let entitlements: any PremiumProviding
    private let scheduler: ReminderScheduler
    private let haptics: any HapticPlaying

    init(topics: Topics, profile: any ProfileStoring, library: any LibraryStoring, entitlements: any PremiumProviding,
         scheduler: ReminderScheduler, haptics: any HapticPlaying) {
        self.families = topics.families; self.profile = profile; self.library = library
        self.entitlements = entitlements; self.scheduler = scheduler; self.haptics = haptics
    }

    var isPremium: Bool { entitlements.isPremium }
    var canAdd: Bool { isPremium || reminders.count < Rules.freeReminderCount }

    func load() {
        reminders = profile.reminders()
        collectionNames = library.collections().map(\.name)
    }

    /// Les rappels au-delà du premier sont inactifs en gratuit.
    func isLocked(_ reminder: Reminder) -> Bool {
        !isPremium && reminders.firstIndex(where: { $0 === reminder }).map { $0 >= Rules.freeReminderCount } ?? false
    }

    func add() {
        editing = profile.addReminder()
        haptics.play(.light)
        load()
    }

    func edit(_ reminder: Reminder) {
        editing = reminder
    }

    func save() {
        guard let editing else { return }
        editing.endMinute = max(editing.endMinute, editing.startMinute)
        profile.save()
        haptics.play(.success)
        self.editing = nil
        load()
        Task { await scheduler.reschedule() }
    }

    func delete() {
        guard let editing else { return }
        profile.delete(editing)
        haptics.play(.heavy)
        self.editing = nil
        load()
        Task { await scheduler.reschedule() }
    }

    func cancel() {
        editing = nil
        load()
    }

    // MARK: Édition

    func setCount(_ delta: Int) {
        guard let editing else { return }
        editing.count = min(max(editing.count + delta, 1), Rules.reminderMaxPerDay)
        haptics.play(.selection)
    }

    func shift(start: Bool, by delta: Int) {
        guard let editing else { return }
        let step = Rules.reminderStepMinutes * delta
        if start {
            editing.startMinute = min(max(editing.startMinute + step, 0), 23 * 60 + 30)
        } else {
            editing.endMinute = min(max(editing.endMinute + step, editing.startMinute), 23 * 60 + 30)
        }
        haptics.play(.selection)
    }

    func toggle(weekday: Int) {
        guard let editing else { return }
        if editing.weekdays.contains(weekday) {
            guard editing.weekdays.count > 1 else { return }
            editing.weekdays.removeAll { $0 == weekday }
        } else {
            editing.weekdays.append(weekday)
            editing.weekdays.sort()
        }
        haptics.play(.selection)
    }

    func setSource(_ source: ReminderSource, id: String? = nil) {
        guard let editing else { return }
        editing.source = source
        editing.sourceID = id
        haptics.play(.soft)
    }

    func setSound(_ sound: String) {
        editing?.soundID = sound
        haptics.play(.selection)
    }

    static func time(_ minute: Int) -> String {
        String(format: "%d:%02d", minute / 60, minute % 60)
    }
}

extension ReminderSource {
    var title: LocalizedStringKey {
        switch self {
        case .fichesDuJour: "Fiches du jour"
        case .aRetenir: "À retenir"
        case .collection: "Une collection"
        case .famille: "Une famille"
        }
    }
}

struct RemindersView: View {
    @State var viewModel: RemindersViewModel
    @Environment(AppRouter.self) private var router

    /// Initiales des jours du lundi (1) au dimanche (7), dans la langue de l'appareil (L M M J V S D, M T W T F S S).
    private let weekdayLetters: [(Int, String)] = {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        return (1...7).map { ($0, symbols[$0 % 7]) }
    }()

    var body: some View {
        SheetPage("Rappels") {
            ScrollView {
                VStack(alignment: .leading, spacing: SagaceMetrics.rowSpacing) {
                    if let reminder = viewModel.editing {
                        editor(reminder)
                    } else {
                        list
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.bottom, 16)
            }
        }
        .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private var list: some View {
        if viewModel.reminders.isEmpty {
            EmptyState(systemImage: "bell", text: "Une fiche au bon moment, chaque jour.")
        }
        ForEach(viewModel.reminders) { reminder in
            Button { viewModel.edit(reminder) } label: {
                HStack(spacing: 14) {
                    Image(systemName: "bell.fill").font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reminder.source.title).fontStyle(.rowTitle)
                        Text(verbatim: reminder.count == 1
                             ? RemindersViewModel.time(reminder.startMinute)
                             : "\(RemindersViewModel.time(reminder.startMinute)) – \(RemindersViewModel.time(reminder.endMinute)) · \(reminder.count)×")
                            .textStyle(.meta)
                    }
                    Spacer()
                    if viewModel.isLocked(reminder) { Image(systemName: "lock.fill").foregroundStyle(.vPurple) }
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.vTextSecondary)
                }
                .foregroundStyle(.vTextPrimary)
                .padding(16)
                .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                .opacity(viewModel.isLocked(reminder) ? 0.6 : 1)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        if viewModel.canAdd {
            PrimaryButton("Ajouter un rappel", systemImage: "plus", haptic: nil) { viewModel.add() }
                .padding(.top, 6)
        } else {
            ProBanner { router.stackedPaywall = .reminders }
                .padding(.top, 6)
        }
    }

    @ViewBuilder
    private func editor(_ reminder: Reminder) -> some View {
        sectionTitle("Source")
        FlowLayout {
            ForEach(ReminderSource.allCases, id: \.self) { source in
                Chip(source.title, isActive: reminder.source == source) { viewModel.setSource(source, id: defaultID(for: source)) }
            }
        }
        if reminder.source == .collection {
            FlowLayout {
                ForEach(viewModel.collectionNames, id: \.self) { name in
                    Chip(verbatim: name, isActive: reminder.sourceID == name) { viewModel.setSource(.collection, id: name) }
                }
            }
        }
        if reminder.source == .famille {
            FlowLayout {
                ForEach(viewModel.families) { family in
                    Chip(verbatim: family.name, isActive: reminder.sourceID == family.id.rawValue) { viewModel.setSource(.famille, id: family.id.rawValue) }
                }
            }
        }
        sectionTitle("Nombre par jour")
        stepper(value: "\(reminder.count)", minus: { viewModel.setCount(-1) }, plus: { viewModel.setCount(1) })
        sectionTitle("Entre")
        stepper(value: RemindersViewModel.time(reminder.startMinute), minus: { viewModel.shift(start: true, by: -1) }, plus: { viewModel.shift(start: true, by: 1) })
        if reminder.count > 1 {
            sectionTitle("Et")
            stepper(value: RemindersViewModel.time(reminder.endMinute), minus: { viewModel.shift(start: false, by: -1) }, plus: { viewModel.shift(start: false, by: 1) })
        }
        sectionTitle("Jours")
        HStack(spacing: 6) {
            ForEach(weekdayLetters, id: \.0) { weekday, letter in
                let active = reminder.weekdays.contains(weekday)
                Button { viewModel.toggle(weekday: weekday) } label: {
                    Text(verbatim: letter)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(active ? Color.vOnInverse : .vTextPrimary)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(active ? Color.vInverse : .vSurfaceRaised, in: .circle)
                }
                .accessibilityLabel(Text(verbatim: Calendar.current.standaloneWeekdaySymbols[weekday % 7]))
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        sectionTitle("Son")
        HStack(spacing: 8) {
            Chip("Par défaut", isActive: reminder.soundID == "default") { viewModel.setSound("default") }
            Chip("Positif", isActive: reminder.soundID == "positive") { viewModel.setSound("positive") }
            Chip("Classique", isActive: reminder.soundID == "classical") { viewModel.setSound("classical") }
        }
        PrimaryButton("Enregistrer", haptic: nil) { viewModel.save() }
            .padding(.top, 10)
        SecondaryButton("Supprimer", systemImage: "trash", haptic: nil) { viewModel.delete() }
    }

    private func defaultID(for source: ReminderSource) -> String? {
        switch source {
        case .collection: viewModel.collectionNames.first
        case .famille: viewModel.families.first?.id.rawValue
        case .fichesDuJour, .aRetenir: nil
        }
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title).textStyle(.metricLabel).textCase(.uppercase).padding(.top, 10)
    }

    /// Stepper "− n +" de Sudoku a Day.
    private func stepper(value: String, minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        HStack {
            CircleButton(systemImage: "minus", accessibilityLabel: "Moins", size: 44, haptic: nil, action: minus)
            Spacer()
            Text(verbatim: value).font(.system(size: 24, weight: .bold).monospacedDigit()).foregroundStyle(.vTextPrimary)
            Spacer()
            CircleButton(systemImage: "plus", accessibilityLabel: "Plus", size: 44, haptic: nil, action: plus)
        }
        .padding(8)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
    }
}
