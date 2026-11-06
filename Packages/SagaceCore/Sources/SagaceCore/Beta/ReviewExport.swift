import Foundation

/// Relectures d'un testeur (verdicts « Juste », signalements, mots proposés), en CSV pour le pipeline de contenu.
public enum ReviewExport {
    public struct Entry: Equatable, Sendable {
        public let ficheID: String
        public let headword: String
        public let reason: ReportReason
        public let comment: String?
        public let createdAt: Date

        public init(ficheID: String, headword: String, reason: ReportReason, comment: String?, createdAt: Date) {
            self.ficheID = ficheID; self.headword = headword; self.reason = reason; self.comment = comment; self.createdAt = createdAt
        }
    }

    public static let header = "fiche_id,mot,verdict,commentaire,date"

    /// Une ligne par entrée, de la plus ancienne à la plus récente, dates ISO 8601.
    public static func csv(_ entries: [Entry]) -> String {
        let rows = entries.sorted { $0.createdAt < $1.createdAt }.map { entry in
            [entry.ficheID, entry.headword, entry.reason.rawValue, entry.comment ?? "", entry.createdAt.ISO8601Format()]
                .map(escape)
                .joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
