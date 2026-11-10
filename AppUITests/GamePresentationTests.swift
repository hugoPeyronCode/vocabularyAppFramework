import XCTest

@MainActor
final class GamePresentationTests: XCTestCase {
    private func assertNearBottom(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.isHittable)
        XCTAssertGreaterThan(element.frame.maxY, app.frame.height - 90)
        XCTAssertLessThan(element.frame.maxY, app.frame.height)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testChallengeAndCrosswordOpenFullScreen() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-hideTips", "-debugPremium", "-debugSheet", "challenge:rush", "-AppleLanguages", "(en)"]
        app.launch()
        let start = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Start", "Commencer")).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        start.tap()
        XCTAssertTrue(app.staticTexts["game.prompt"].waitForExistence(timeout: 30))
        XCTAssertLessThan(app.buttons["game.close"].frame.midY, app.frame.height * 0.15)
        let answers = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "answer."))
        if let lowest = answers.allElementsBoundByIndex.max(by: { $0.frame.maxY < $1.frame.maxY }) {
            assertNearBottom(lowest, in: app)
        } else { XCTFail("Réponses absentes") }
        capture("Rush bottom controls")
        app.buttons["game.close"].tap()
        app.terminate()
        app.launchArguments = ["-skipOnboarding", "-hideTips", "-debugPremium", "-debugSheet", "crossword", "-AppleLanguages", "(en)"]
        app.launch()
        XCTAssertTrue(app.buttons["game.close"].waitForExistence(timeout: 20))
        let delete = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Clear", "Effacer")).firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 30))
        assertNearBottom(delete, in: app)
        capture("Crossword bottom keyboard")
        XCTAssertLessThan(app.buttons["game.close"].frame.midY, app.frame.height * 0.15)
    }

    func testTrueFalseLargeText() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-hideTips", "-debugPremium", "-debugSheet", "game:justeOuFautif", "-AppleLanguages", "(fr)", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXL"]
        app.launch()
        let answer = app.buttons["answer.juste"]
        XCTAssertTrue(answer.waitForExistence(timeout: 20))
        assertNearBottom(answer, in: app)
        XCTAssertLessThan(app.staticTexts["game.prompt"].frame.maxY, answer.frame.minY)
        capture("True false large text")
        answer.tap()
        let next = app.buttons["Continuer"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        if !next.isHittable { app.swipeUp() }
        XCTAssertTrue(next.isHittable)
        next.tap()
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
    }

    func testGameOpensFullScreenFromHub() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-hideTips", "-debugPremium", "-debugSheet", "practice", "-AppleLanguages", "(en)"]
        app.launch()
        let game = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] %@ OR label CONTAINS[cd] %@", "The right word", "Le mot juste")).firstMatch
        XCTAssertTrue(game.waitForExistence(timeout: 20))
        game.tap()
        let close = app.buttons["game.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        XCTAssertLessThan(close.frame.midY, app.frame.height * 0.15, "Le bouton doit être en haut du plein écran, pas dans une sheet.")
        XCTAssertTrue(app.buttons["answer.0"].waitForExistence(timeout: 30))
        let titles = app.staticTexts.matching(identifier: "game.title")
        XCTAssertEqual(titles.count, 1)
        XCTAssertLessThan(titles.firstMatch.frame.midY, app.frame.height * 0.15)
        assertNearBottom(app.buttons["answer.2"], in: app)
        capture("Game bottom answers")
        app.buttons["answer.0"].tap()
        let next = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Continue", "Continuer")).firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        assertNearBottom(next, in: app)
        capture("Game answer feedback")
        close.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Profil", "Profile")).firstMatch.waitForExistence(timeout: 10))
    }
}
