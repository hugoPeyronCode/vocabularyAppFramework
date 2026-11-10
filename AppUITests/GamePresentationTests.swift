import XCTest

@MainActor
final class GamePresentationTests: XCTestCase {
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
        app.buttons["game.close"].tap()
        app.terminate()
        app.launchArguments = ["-skipOnboarding", "-hideTips", "-debugPremium", "-debugSheet", "crossword", "-AppleLanguages", "(en)"]
        app.launch()
        XCTAssertTrue(app.buttons["game.close"].waitForExistence(timeout: 20))
        let delete = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Clear", "Effacer")).firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 30))
        XCTAssertLessThan(app.buttons["game.close"].frame.midY, app.frame.height * 0.15)
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
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "Game full screen"
        capture.lifetime = .keepAlways
        add(capture)
        app.buttons["answer.0"].tap()
        let next = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Continue", "Continuer")).firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Profil", "Profile")).firstMatch.waitForExistence(timeout: 10))
    }
}
