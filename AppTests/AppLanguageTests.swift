import Foundation
import SagaceCore
import Testing
@testable import VocabularyAppFramework

@MainActor
@Suite("Langue : packs, traductions et révisions")
struct AppLanguageTests {
    @Test("Les deux packs embarqués et leurs rubriques sont chargeables")
    func bundledPacks() async throws {
        let (french, frTopics) = try await AppContent.load(.fr, visibility: .development)
        let (english, enTopics) = try await AppContent.load(.en, visibility: .development)
        #expect(!french.isEmpty && !english.isEmpty)
        #expect(french.fiches.allSatisfy { $0.language == .fr })
        #expect(english.fiches.allSatisfy { $0.language == .en })
        #expect(Set(french.fiches.map(\.id)).isDisjoint(with: english.fiches.map(\.id)))
        #expect(frTopics.families.map(\.id) == enTopics.families.map(\.id))
        #expect(frTopics.themes.map(\.id) == enTopics.themes.map(\.id))
        #expect(enTopics.themes.first?.name == "Work")
    }

    @Test("Les chaînes hors SwiftUI suivent la langue choisie, même si iOS en utilise une autre")
    func localizedResources() {
        #expect(AppLocalization.string("Jeux", locale: Locale(identifier: "fr")) == "Jeux")
        #expect(AppLocalization.string("Jeux", locale: Locale(identifier: "en")) == "Games")
        #expect(AppLocalization.string("Une fiche suffit pour la garder.", locale: Locale(identifier: "en")) != "Une fiche suffit pour la garder.")
    }

    @Test("Les révisions et compteurs ne mélangent pas les packs ; aucun mot enregistré n'est effacé")
    func reviewsStayInTheirLanguage() throws {
        let world = try TestWorld()
        let frenchID = try #require(world.content.fiches.first?.id)
        let englishID = "en.language-test"
        let twoDaysAgo = Date.now.addingTimeInterval(-2 * 86_400)
        _ = world.progress.sort(frenchID, as: .toLearn, at: twoDaysAgo)
        _ = world.progress.sort(englishID, as: .toLearn, at: twoDaysAgo)
        let hub = PracticeHubViewModel(content: world.content, topics: world.topics, progress: world.progress,
                                       recorder: world.practice, entitlements: FakePremium(true), day: SagaceDay(), now: { .now })
        hub.load()
        #expect(hub.dueReviews == [frenchID])
        let explore = ExploreViewModel(content: world.content, topics: world.topics, store: world.progress,
                                       library: world.library, entitlements: FakePremium(true), haptics: SilentHaptics(), now: { .now })
        explore.load()
        #expect(explore.counts.toLearn == 1)
        #expect(world.progress.allProgress()[englishID]?.sorting == .toLearn)
        #expect(world.progress.allProgress()[frenchID]?.sorting == .toLearn)
    }
}
