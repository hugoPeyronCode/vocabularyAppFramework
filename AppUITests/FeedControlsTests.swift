import XCTest

@MainActor
final class FeedControlsTests: XCTestCase {
    private func launch(language: String = "fr", largeText: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-hideTips", "-debugPremium", "-AppleLanguages", "(\(language))"]
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["feed.games"].waitForExistence(timeout: 20))
        return app
    }

    private func checkLayout(_ app: XCUIApplication) {
        let day = app.buttons["feed.day.today"].firstMatch
        let menu = app.buttons["feed.card.options"].firstMatch
        let known = app.buttons["feed.known"].firstMatch
        let learn = app.buttons["feed.learn"].firstMatch
        let games = app.buttons["feed.games"]
        XCTAssertTrue(known.waitForExistence(timeout: 15))
        XCTAssertTrue(known.isHittable && learn.isHittable && menu.isHittable && games.isHittable)
        XCTAssertLessThan(day.frame.maxY, menu.frame.minY)
        XCTAssertLessThan(menu.frame.maxY, known.frame.minY)
        XCTAssertLessThan(learn.frame.maxY, games.frame.minY)
        XCTAssertGreaterThanOrEqual(games.frame.height, 64)
        XCTAssertGreaterThan(games.frame.width, min(app.frame.width, 640) * 0.75)
    }

    private func visible(_ query: XCUIElementQuery) -> XCUIElement {
        query.allElementsBoundByIndex.first(where: { $0.isHittable }) ?? query.firstMatch
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func closeSheet(_ app: XCUIApplication) {
        let close = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Fermer", "Close")).firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        close.tap()
        XCTAssertTrue(app.buttons["feed.card.options"].firstMatch.waitForExistence(timeout: 10))
    }

    func testFrenchCardActionsAndHistory() {
        XCUIDevice.shared.orientation = .portrait
        let app = launch()
        checkLayout(app)
        XCTAssertEqual(app.buttons["feed.known"].firstMatch.label, "Je connais")
        capture(app, name: "Feed French portrait")

        app.buttons["feed.card.options"].firstMatch.tap()
        let info = app.buttons["Fiche détaillée"]
        XCTAssertTrue(info.waitForExistence(timeout: 5))
        info.tap()
        closeSheet(app)
        app.buttons["feed.card.options"].firstMatch.tap()
        app.buttons["Partager"].tap()
        XCTAssertTrue(app.buttons["Copier le texte"].waitForExistence(timeout: 10))
        closeSheet(app)

        let words = app.staticTexts.matching(identifier: "feed.headword")
        let knownWord = visible(words).label
        app.buttons["feed.known"].firstMatch.tap()
        let next = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            MainActor.assumeIsolated { self.visible(words).label != knownWord }
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [next], timeout: 5), .completed)
        let learningWord = visible(words).label
        visible(app.buttons.matching(identifier: "feed.learn")).tap()
        app.buttons["feed.day.today"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", knownWord)).firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", learningWord)).firstMatch.exists)
        closeSheet(app)
        app.buttons["feed.games"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Le mot juste")).firstMatch.waitForExistence(timeout: 10))
    }

    func testEnglishLargeTextAndLandscape() {
        XCUIDevice.shared.orientation = .portrait
        let app = launch(language: "en", largeText: true)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        if UIDevice.current.userInterfaceIdiom == .pad {
            let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                MainActor.assumeIsolated { app.frame.width > app.frame.height }
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 5), .completed)
        }
        checkLayout(app)
        XCTAssertEqual(app.buttons["feed.known"].firstMatch.label, "I know this")
        capture(app, name: "Feed English large text landscape")
    }
}
