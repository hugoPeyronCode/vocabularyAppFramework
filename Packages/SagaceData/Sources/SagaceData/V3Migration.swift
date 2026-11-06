import Foundation
import SagaceCore

/// Ce que la migration a trouvé, pour MIG-01 et l'événement `migration_v3_completed`.
public struct V3MigrationReport: Equatable, Sendable {
    /// Mots aimés dans `savedWords.json`.
    public let likedCount: Int
    /// Mots aimés importés en "À retenir" (fiche correspondante dans un pack chargé).
    public let importedCount: Int
    /// L'utilisateur avait choisi une icône alternative v3 (à remettre par défaut).
    public let hadAlternateIcon: Bool
    /// `com.words.premiumAccess` valait `true`.
    public let legacyPremiumFlag: Bool

    public var hadSavedWords: Bool { likedCount > 0 }
}

/// Migration des données de Words v3 au premier lancement de la v4 (`04_MIGRATION.md` section 7, étapes 1, 2, 4 et 5).
/// Les effets système (icône, notifications, achats StoreKit) sont faits par l'app à partir du rapport.
@MainActor
public struct V3Migration {
    public enum Key {
        public static let isShowingOnboarding = "isShowingOnboarding"
        public static let activeIcon = "active_icon"
        public static let quizApparitionValue = "quizApparitionValue"
        public static let premiumAccess = "com.words.premiumAccess"
        public static let all = [isShowingOnboarding, activeIcon, quizApparitionValue, premiumAccess]
    }

    public static let savedWordsFilename = "savedWords.json"
    public static let backupFilename = "savedWords.v3.backup.json"
    private static let defaultIconName = "AppIcon"

    private let defaults: UserDefaults
    private let documentsURL: URL
    private let store: ProgressStore
    private let content: ContentRepository
    private let fileManager: FileManager

    public init(defaults: UserDefaults, documentsURL: URL, store: ProgressStore, content: ContentRepository, fileManager: FileManager = .default) {
        self.defaults = defaults; self.documentsURL = documentsURL; self.store = store
        self.content = content; self.fileManager = fileManager
    }

    private var savedWordsURL: URL { documentsURL.appending(path: Self.savedWordsFilename) }
    private var backupURL: URL { documentsURL.appending(path: Self.backupFilename) }

    /// Une installation v3 laisse `isShowingOnboarding` dans les réglages ou un fichier de mots aimés.
    public var isNeeded: Bool {
        guard !store.profile.migratedFromV3 else { return false }
        return defaults.object(forKey: Key.isShowingOnboarding) != nil || fileManager.fileExists(atPath: savedWordsURL.path)
    }

    public func run(at now: Date = .now) -> V3MigrationReport {
        let liked = readLikedHeadwords()
        let imported = importLikedWords(liked, at: now)
        let hadAlternateIcon = defaults.string(forKey: Key.activeIcon).map { $0 != Self.defaultIconName } ?? false
        let legacyPremium = defaults.bool(forKey: Key.premiumAccess)

        let profile = store.profile
        profile.legacyPremiumFlag = legacyPremium
        profile.migratedFromV3 = true
        profile.hasCompletedOnboarding = true
        store.save()

        Key.all.forEach(defaults.removeObject(forKey:))
        backUpSavedWords()

        return V3MigrationReport(likedCount: liked.count, importedCount: imported, hadAlternateIcon: hadAlternateIcon, legacyPremiumFlag: legacyPremium)
    }

    // MARK: Étape 1 : mots aimés

    /// Format v3 : tableau de `Word` (`Headword`, `Definition`, `Context sentence`…). Seul le mot sert.
    private struct LegacyWord: Decodable {
        let Headword: String
    }

    func readLikedHeadwords() -> [String] {
        guard let data = try? Data(contentsOf: savedWordsURL),
              let words = try? JSONDecoder().decode([LegacyWord].self, from: data) else { return [] }
        var seen = Set<String>()
        return words.map(\.Headword).filter { seen.insert($0.lowercased()).inserted }
    }

    /// Chaque mot aimé qui correspond à une fiche anglaise (même mot, casse ignorée) entre en révision.
    /// Les autres sont gardés dans le profil pour l'arrivée du pack anglais historique (M8).
    /// Mots aimés v3 → « À retenir », par le pack anglais historique. Ceux qui n'y sont pas restent en attente
    /// (`UserProfile.pendingV3Headwords`) ; l'app les retente quand elle charge le pack anglais.
    @discardableResult
    public func importLikedWords(_ headwords: [String], at now: Date) -> Int {
        let english = Dictionary(
            content.fiches.filter { $0.language == .en }.map { ($0.headword.lowercased(), $0.id) },
            uniquingKeysWith: { first, _ in first }
        )
        var imported = 0
        var pending: [String] = []
        for headword in headwords {
            if let ficheID = english[headword.lowercased()] {
                store.importToLearn(ficheID, at: now)
                imported += 1
            } else {
                pending.append(headword)
            }
        }
        store.profile.pendingV3Headwords = pending
        return imported
    }

    // MARK: Étape 5 : sauvegarde

    /// `savedWords.json` devient `savedWords.v3.backup.json` (à garder jusqu'à la v4.1).
    func backUpSavedWords() {
        guard fileManager.fileExists(atPath: savedWordsURL.path) else { return }
        try? fileManager.removeItem(at: backupURL)
        try? fileManager.moveItem(at: savedWordsURL, to: backupURL)
    }
}
