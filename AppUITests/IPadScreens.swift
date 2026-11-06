import XCTest

/// Captures de vérification de l'interface iPad (`09_IPAD.md`), en portrait puis en paysage, lancées par
/// `Scripts/ipad_screens.sh` seulement, sur le simulateur iPad : sans `IPAD_SCREENS_DIR`, chaque test est ignoré.
/// Le script règle l'apparence et la taille du texte du simulateur avant chaque série.
@MainActor
final class IPadScreens: XCTestCase {
    private var directory: URL?
    private var suffix = ""

    override func setUp() async throws {
        guard let path = ProcessInfo.processInfo.environment["IPAD_SCREENS_DIR"], !path.isEmpty else {
            throw XCTSkip("Captures iPad : lancer Scripts/ipad_screens.sh")
        }
        directory = URL(fileURLWithPath: path)
        suffix = ProcessInfo.processInfo.environment["IPAD_SCREENS_SUFFIX"] ?? ""
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
    }

    private func launch(_ arguments: [String] = [], onboarding: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = (onboarding ? [] : ["-skipOnboarding"]) + ["-hideTips", "-demoProgress", "-hideBetaReview",
                               "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"] + arguments
        app.launch()
        return app
    }

    /// Capture en portrait, tourne en paysage, capture encore.
    private func capture(_ name: String) throws {
        let directory = try XCTUnwrap(directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            sleep(2)
            let label = orientation == .portrait ? "portrait" : "paysage"
            try XCUIScreen.main.screenshot().pngRepresentation.write(to: directory.appending(path: "\(name)-\(label)\(suffix).png"))
        }
    }

    func test01Feed() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["Écouter la prononciation"].firstMatch.waitForExistence(timeout: 20))
        try capture("01-feed")
    }

    func test02Fiche() throws {
        let app = launch(["-debugSheet", "fiche:fr.differend"])
        XCTAssertTrue(app.staticTexts["SENS"].firstMatch.waitForExistence(timeout: 20))
        try capture("02-fiche")
    }

    func test03Explorer() throws {
        let app = launch(["-debugSheet", "explore"])
        XCTAssertTrue(app.staticTexts["Bibliothèque"].firstMatch.waitForExistence(timeout: 20))
        try capture("03-explorer")
    }

    func test04Jeux() throws {
        let app = launch(["-debugSheet", "practice"])
        XCTAssertTrue(app.staticTexts["Défis"].firstMatch.waitForExistence(timeout: 20))
        try capture("04-jeux")
    }

    func test05Question() throws {
        let app = launch(["-debugSheet", "game:motJuste"])
        let answer = app.buttons["answer.0"]
        XCTAssertTrue(answer.waitForExistence(timeout: 20))
        answer.tap()
        XCTAssertTrue(app.buttons["Continuer"].waitForExistence(timeout: 5))
        try capture("05-question")
    }

    func test06Stats() throws {
        let app = launch(["-debugSheet", "stats"])
        XCTAssertTrue(app.staticTexts["Stats"].firstMatch.waitForExistence(timeout: 20))
        try capture("06-stats")
    }

    func test07Profil() throws {
        let app = launch(["-debugSheet", "profile"])
        XCTAssertTrue(app.staticTexts["Profil"].firstMatch.waitForExistence(timeout: 20))
        try capture("07-profil")
    }

    func test08Paywall() throws {
        let app = launch(["-debugSheet", "paywall"])
        XCTAssertTrue(app.buttons["Restaurer"].firstMatch.waitForExistence(timeout: 20))
        try capture("08-paywall")
    }

    func test09Onboarding() throws {
        let app = launch(onboarding: true)
        let start = app.buttons["Commencer"]
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        try capture("09-onboarding")
    }
}
