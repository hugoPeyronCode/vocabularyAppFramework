import Foundation
import Testing
@testable import SagaceCore

@Suite("Langue de l'app")
struct AppLanguagePreferenceTests {
    @Test("Automatique conserve le choix historique selon l'appareil")
    func automatic() {
        #expect(AppLanguagePreference.automatic.resolved(preferredLanguages: ["fr-CA", "en"]) == .fr)
        #expect(AppLanguagePreference.automatic.resolved(preferredLanguages: ["en-GB", "fr"]) == .en)
        #expect(AppLanguagePreference.automatic.resolved(preferredLanguages: ["de-DE"]) == .en)
        #expect(AppLanguagePreference.automatic.resolved(preferredLanguages: []) == .fr)
    }

    @Test("Le choix explicite prime sur la langue de l'appareil")
    func override() {
        #expect(AppLanguagePreference.fr.resolved(preferredLanguages: ["en-US"]) == .fr)
        #expect(AppLanguagePreference.en.resolved(preferredLanguages: ["fr-FR"]) == .en)
        #expect(AppLanguagePreference.en.resolved(englishPackAvailable: false) == .fr)
    }

    @Test("Choix conservé entre ouvertures, retour à Automatique et valeur inconnue")
    func persistence() throws {
        let suite = "language-test.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(AppLanguagePreference.saved(in: defaults) == .automatic)
        for preference in AppLanguagePreference.allCases {
            preference.save(in: defaults)
            let reopened = try #require(UserDefaults(suiteName: suite))
            #expect(AppLanguagePreference.saved(in: reopened) == preference)
        }
        AppLanguagePreference.automatic.save(in: defaults)
        #expect(AppLanguagePreference.saved(in: defaults).resolved(preferredLanguages: ["fr"]) == .fr)
        defaults.set("obsolete", forKey: AppLanguagePreference.defaultsKey)
        #expect(AppLanguagePreference.saved(in: defaults) == .automatic)
    }
}
