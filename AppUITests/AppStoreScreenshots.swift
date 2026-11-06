import XCTest

/// Captures App Store (`07_APP_STORE.md`), lancées par `Scripts/screenshots.sh` seulement : sans `SCREENSHOTS_DIR`,
/// chaque test est ignoré. Le script règle l'apparence du simulateur (clair, sombre) avant chaque capture.
@MainActor
final class AppStoreScreenshots: XCTestCase {
    private var directory: URL?

    override func setUp() async throws {
        guard let path = ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"], !path.isEmpty else {
            throw XCTSkip("Captures App Store : lancer Scripts/screenshots.sh")
        }
        directory = URL(fileURLWithPath: path)
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-hideTips", "-demoProgress", "-debugPremium", "-hideBetaReview",
                               "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"] + arguments
        app.launch()
        return app
    }

    private func save(_ name: String) throws {
        let directory = try XCTUnwrap(directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: directory.appending(path: "\(name).png"))
    }

    /// 1. La fiche « éminent » plein écran.
    func test1Fiche() throws {
        let app = launch(["-debugSheet", "fiche:fr.eminent"])
        XCTAssertTrue(app.staticTexts["éminent"].firstMatch.waitForExistence(timeout: 15))
        sleep(1)
        try save("1-fiche")
    }

    /// 2. La fiche détaillée, à la phrase d'auteur (ou aux exemples tant que le pack n'en a pas).
    func test2Auteur() throws {
        let app = launch(["-debugSheet", "fiche:fr.eminent"])
        XCTAssertTrue(app.staticTexts["éminent"].firstMatch.waitForExistence(timeout: 15))
        let target = app.staticTexts["CHEZ LES AUTEURS"].exists ? app.staticTexts["CHEZ LES AUTEURS"] : app.staticTexts["EXEMPLES"]
        for _ in 0..<4 where target.frame.minY > app.frame.height * 0.45 { app.swipeUp(velocity: .slow) }
        sleep(1)
        try save("2-auteur")
    }

    /// 3. Le feed : tri « Je savais » / « À retenir » et la série.
    func test3Tri() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["Écouter la prononciation"].firstMatch.waitForExistence(timeout: 15))
        sleep(1)
        try save("3-tri")
    }

    /// 4. Juste ou fautif, après une bonne réponse (« Exact. ») : l'explication. On relance tant que la réponse est fausse.
    func test4Jeu() throws {
        for attempt in 0..<6 {
            let app = launch(["-debugSheet", "game:justeOuFautif"])
            let answer = app.buttons[attempt.isMultiple(of: 2) ? "answer.fautif" : "answer.juste"]
            XCTAssertTrue(answer.waitForExistence(timeout: 15))
            answer.tap()
            XCTAssertTrue(app.buttons["Continuer"].waitForExistence(timeout: 5))
            if app.staticTexts["Exact."].exists {
                sleep(1)
                try save("4-jeu")
                return
            }
            app.terminate()
        }
        XCTFail("Aucune bonne réponse en 6 essais")
    }

    /// 6. Stats et mots maîtrisés.
    func test6Stats() throws {
        let app = launch(["-debugSheet", "stats"])
        XCTAssertTrue(app.staticTexts["Stats"].firstMatch.waitForExistence(timeout: 15))
        sleep(1)
        try save("6-stats")
    }
}
