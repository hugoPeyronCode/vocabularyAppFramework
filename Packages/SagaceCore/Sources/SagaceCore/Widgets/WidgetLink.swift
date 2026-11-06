import Foundation

/// Liens ouverts par un toucher sur un widget : `sagace://fiche/<id>`, `sagace://revision`, `sagace://serie`.
public enum WidgetLink: Equatable, Sendable {
    case fiche(String)
    case revision
    case serie

    public static let scheme = "sagace"

    public var url: URL {
        switch self {
        case .fiche(let id): URL(string: "\(Self.scheme)://fiche/\(id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id)")!
        case .revision: URL(string: "\(Self.scheme)://revision")!
        case .serie: URL(string: "\(Self.scheme)://serie")!
        }
    }

    public var kind: WidgetKind {
        switch self {
        case .fiche: .ficheDuJour
        case .revision: .revision
        case .serie: .serie
        }
    }

    public init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        switch url.host() {
        case "fiche":
            guard let id = url.pathComponents.dropFirst().first, !id.isEmpty else { return nil }
            self = .fiche(id)
        case "revision": self = .revision
        case "serie": self = .serie
        default: return nil
        }
    }
}
