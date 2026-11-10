import XCTest

@MainActor
final class AppLanguageTests: XCTestCase {
    /// Même parcours sur iPhone et iPad : français forcé sur appareil anglais, anglais, puis automatique.
    func testSwitchLanguageAndRelaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-hideTips", "-debugPremium", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        openSettings(app)
        if app.buttons["appLanguage.fr"].isSelected {
            app.buttons["appLanguage.en"].tap()
            XCTAssertTrue(app.buttons["Listen to pronunciation"].firstMatch.waitForExistence(timeout: 20))
            openSettings(app)
        }
        let settingsScreenshot = XCTAttachment(screenshot: app.screenshot())
        settingsScreenshot.name = "Language settings"
        settingsScreenshot.lifetime = .keepAlways
        add(settingsScreenshot)
        app.buttons["appLanguage.fr"].tap()
        XCTAssertTrue(app.buttons["Écouter la prononciation"].firstMatch.waitForExistence(timeout: 20))
        assertWord(app, language: "fr")

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Écouter la prononciation"].firstMatch.waitForExistence(timeout: 20))
        assertWord(app, language: "fr")

        openSettings(app)
        app.buttons["appLanguage.en"].tap()
        XCTAssertTrue(app.buttons["Listen to pronunciation"].firstMatch.waitForExistence(timeout: 20))
        assertWord(app, language: "en")

        openSettings(app)
        app.buttons["appLanguage.automatic"].tap()
        XCTAssertTrue(app.buttons["Listen to pronunciation"].firstMatch.waitForExistence(timeout: 20))
        assertWord(app, language: "en")
    }

    private func openSettings(_ app: XCUIApplication) {
        let profile = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Profil", "Profile")).firstMatch
        XCTAssertTrue(profile.waitForExistence(timeout: 20))
        profile.tap()
        let settings = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Réglages", "Settings")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()
        XCTAssertTrue(app.buttons["appLanguage.fr"].waitForExistence(timeout: 10))
    }

    private func assertWord(_ app: XCUIApplication, language: String) {
        let word = app.staticTexts["feed.headword"].firstMatch
        XCTAssertTrue(word.waitForExistence(timeout: 10))
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try! Data(contentsOf: root.appending(path: "content/\(language)/fiches.json"))
        let fiches = try! JSONSerialization.jsonObject(with: data) as! [[String: Any]]
        let headword = word.label
        XCTAssertTrue(fiches.contains { $0["headword"] as? String == headword }, "\(headword) doit venir du pack \(language)")
    }
}
