/// Familles et thèmes du pack (`content/fr/topics.json`).
public struct Topics: Codable, Hashable, Sendable {
    public struct FamilyInfo: Codable, Hashable, Sendable, Identifiable {
        public let id: Family
        public let name: String
        public let intro: String
        public let illustration: String
    }

    public struct ThemeInfo: Codable, Hashable, Sendable, Identifiable {
        public let id: String
        public let name: String
        public let illustration: String
    }

    public let families: [FamilyInfo]
    public let themes: [ThemeInfo]
}
