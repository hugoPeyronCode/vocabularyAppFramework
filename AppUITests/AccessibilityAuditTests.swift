import XCTest

/// Critère M7 : audit VoiceOver sans élément muet sur le feed (FEED-01), une session de jeu (PRA-02) et le paywall (PAY-01),
/// en taille de texte standard et en XXL.
@MainActor
final class AccessibilityAuditTests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private func launch(_ arguments: [String], textSize: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-hideTips"] + arguments
            + (textSize.map { ["-UIPreferredContentSizeCategoryName", $0] } ?? [])
        app.launch()
        return app
    }

    /// Aucun élément sans libellé, aucun élément invisible pour VoiceOver.
    private func audit(_ app: XCUIApplication) throws {
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .elementDetection]) { issue in
            let element = issue.element.map { "« \($0.label) » (\($0.elementType.rawValue))" } ?? "?"
            XCTFail("\(issue.compactDescription) : \(element)")
            return true
        }
    }

    func testFeed() throws {
        let app = launch([])
        XCTAssertTrue(app.buttons["Écouter la prononciation"].firstMatch.waitForExistence(timeout: 15))
        try audit(app)
        // Détails dévoilés au toucher (confusion, usage, exemple).
        app.buttons["Écouter la prononciation"].firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 4)).tap()
        try audit(app)
    }

    func testFeedXXL() throws {
        let app = launch([], textSize: "UICTContentSizeCategoryXXL")
        XCTAssertTrue(app.buttons["Écouter la prononciation"].firstMatch.waitForExistence(timeout: 15))
        try audit(app)
    }

    func testGameSession() throws {
        let app = launch(["-debugSheet", "game:devine", "-debugPremium"])
        let loaded = app.buttons["Fermer"].firstMatch.waitForExistence(timeout: 15)
        if !loaded { print(app.debugDescription) }
        XCTAssertTrue(loaded)
        try audit(app)
        // Après une réponse : retour avec explication et "Continuer".
        app.buttons["answer.0"].tap()
        XCTAssertTrue(app.buttons["Continuer"].waitForExistence(timeout: 5))
        try audit(app)
    }

    func testGameSessionXXL() throws {
        let app = launch(["-debugSheet", "game:paronymes", "-debugPremium"], textSize: "UICTContentSizeCategoryXXL")
        XCTAssertTrue(app.buttons["answer.0"].waitForExistence(timeout: 15))
        try audit(app)
    }

    func testCrossword() throws {
        let app = launch(["-debugSheet", "crossword", "-debugPremium"])
        XCTAssertTrue(app.buttons["Effacer"].waitForExistence(timeout: 15))
        try audit(app)
    }

    func testPaywall() throws {
        let app = launch(["-debugSheet", "paywall"])
        XCTAssertTrue(app.staticTexts["Le mot juste, sans limite."].waitForExistence(timeout: 15))
        try audit(app)
    }

    func testPaywallXXL() throws {
        let app = launch(["-debugSheet", "paywall"], textSize: "UICTContentSizeCategoryXXL")
        XCTAssertTrue(app.staticTexts["Le mot juste, sans limite."].waitForExistence(timeout: 15))
        try audit(app)
    }
}
