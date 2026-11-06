/// Les 5 niveaux de vocabulaire, du test de précision aux badges des fiches.
public enum Level: Int, Codable, Sendable, CaseIterable, Comparable {
    case debutant = 1, elementaire, intermediaire, avance, expert

    public static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }

    public var next: Level? { Level(rawValue: rawValue + 1) }
}
