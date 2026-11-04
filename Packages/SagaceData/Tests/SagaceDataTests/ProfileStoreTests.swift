import Foundation
import SagaceCore
import SwiftData
import Testing
@testable import SagaceData

@MainActor
@Suite("Profil")
struct ProfileStoreTests {
    @Test("Rappels : ajout avec les valeurs par défaut, modification, suppression")
    func reminders() throws {
        let container = try SagaceStore.makeContainer(inMemory: true)
        let store = ProfileStore(context: container.mainContext)
        let reminder = store.addReminder()
        #expect(reminder.count == 1)
        #expect(reminder.startMinute == 9 * 60)
        #expect(reminder.weekdays == Array(1...7))
        reminder.count = 3
        store.save()
        #expect(store.reminders().first?.spec.count == 3)
        store.delete(reminder)
        #expect(store.reminders().isEmpty)
    }

    @Test("Succès : enregistrés une seule fois, avec leur date")
    func achievements() throws {
        let container = try SagaceStore.makeContainer(inMemory: true)
        let store = ProfileStore(context: container.mainContext)
        #expect(store.unlock([.serie3, .maitrise10], at: TestEnv.date()) == [.serie3, .maitrise10])
        #expect(store.unlock([.serie3, .serie7], at: TestEnv.date(days: 1)) == [.serie7])
        #expect(store.achievements().map(\.id) == ["serie_3", "maitrise_10", "serie_7"])
        #expect(store.achievements().first?.unlockedAt == TestEnv.date())
    }

    @Test("Le profil a un identifiant utilisateur stable")
    func userID() throws {
        let (progress, _container) = try TestEnv.makeStore()
        _ = _container
        let id = progress.profile.userID
        #expect(!id.isEmpty)
        #expect(progress.profile.userID == id)
    }
}
