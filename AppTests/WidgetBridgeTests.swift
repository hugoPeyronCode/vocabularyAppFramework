import Foundation
import SagaceCore
import SagaceData
import Testing
@testable import VocabularyAppFramework

/// Critère M6 : répondre à une révision depuis le widget met à jour la boîte de la fiche dans l'app.
@MainActor
@Suite("Widgets : pont avec l'app")
struct WidgetBridgeTests {
    let world: TestWorld
    let files: WidgetStore
    let analytics = RecordingAnalytics()
    let bridge: WidgetBridge

    init() throws {
        world = try TestWorld()
        files = WidgetStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        bridge = WidgetBridge(files: files, progress: world.progress, library: world.library, entitlements: FakePremium(false),
                              analytics: analytics, day: SagaceDay(), now: { .now })
        bridge.content = world.content
    }

    /// Une fiche "À retenir" il y a 2 jours : sa révision (boîte 1, 1 jour) est due.
    private func makeDue() throws -> String {
        let fiche = try #require(world.content.fiches.first)
        _ = world.progress.sort(fiche.id, as: .toLearn, at: .now.addingTimeInterval(-2 * 86_400))
        world.progress.save()
        return fiche.id
    }

    @Test("Bonne réponse dans le widget : la fiche monte en boîte 2 à l'ouverture de l'app")
    func reviewFromWidget() throws {
        let ficheID = try makeDue()
        bridge.refresh()
        let snapshot = try #require(files.readSnapshot())
        let review = try #require(snapshot.reviews.first { $0.ficheID == ficheID })
        files.updateInbox { $0.answer(review, choice: review.correctIndex, at: .now) }

        #expect(bridge.applyInbox())
        #expect(world.progress.allProgress()[ficheID]?.review.box == 2)
        #expect(files.readInbox() == WidgetInbox())
        #expect(analytics.events.contains(.widgetInteraction(kind: .revision, action: .answer)))
        bridge.refresh()
        #expect(files.readSnapshot()?.reviews.contains { $0.ficheID == ficheID } == false)
    }

    @Test("Déjà révisée dans l'app entre-temps : la réponse du widget ne compte pas deux fois")
    func noDoubleAnswer() throws {
        let ficheID = try makeDue()
        bridge.refresh()
        let review = try #require(files.readSnapshot()?.reviews.first { $0.ficheID == ficheID })
        files.updateInbox { $0.answer(review, choice: review.correctIndex, at: .now) }
        _ = world.progress.answerReview(ficheID, correct: true, at: .now)
        bridge.applyInbox()
        #expect(world.progress.allProgress()[ficheID]?.review.box == 2)
    }

    @Test("« À retenir » depuis le widget : la fiche entre en révision")
    func saveFromWidget() throws {
        bridge.refresh()
        let card = try #require(files.readSnapshot()?.cards.first)
        files.updateInbox { $0.saveToLearn(card.id, at: .now) }
        #expect(bridge.applyInbox())
        #expect(world.progress.allProgress()[card.id]?.sorting == .toLearn)
        #expect(world.progress.allProgress()[card.id]?.review.box == 1)
    }
}
