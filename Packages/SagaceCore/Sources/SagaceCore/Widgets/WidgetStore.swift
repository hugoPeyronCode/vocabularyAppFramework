import Foundation

/// Fichiers partagés entre l'app et ses widgets : `snapshot.json` (écrit par l'app) et `inbox.json`
/// (écrit par les widgets, vidé par l'app). Accès coordonnés : l'app et l'extension sont deux processus.
public struct WidgetStore: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// Dossier des widgets dans l'App Group, `nil` sans entitlement.
    public static var shared: WidgetStore? {
        AppGroup.containerURL.map { WidgetStore(directory: $0.appending(path: "Widgets")) }
    }

    private var snapshotURL: URL { directory.appending(path: "snapshot.json") }
    private var inboxURL: URL { directory.appending(path: "inbox.json") }

    public func readSnapshot() -> WidgetSnapshot? {
        read(WidgetSnapshot.self, at: snapshotURL)
    }

    public func write(_ snapshot: WidgetSnapshot) {
        coordinate(writing: snapshotURL) { url in
            try? JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
        }
    }

    public func readInbox() -> WidgetInbox {
        read(WidgetInbox.self, at: inboxURL) ?? WidgetInbox()
    }

    /// Lecture, modification et écriture d'un seul tenant.
    public func updateInbox(_ change: (inout WidgetInbox) -> Void) {
        coordinate(writing: inboxURL) { url in
            var inbox = (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(WidgetInbox.self, from: $0) } ?? WidgetInbox()
            change(&inbox)
            try? JSONEncoder().encode(inbox).write(to: url, options: .atomic)
        }
    }

    /// Côté app : rend la boîte d'envoi et la vide (les fiches repartent du mot du jour).
    public func drainInbox() -> WidgetInbox {
        var drained = WidgetInbox()
        updateInbox { inbox in
            drained = inbox
            inbox = WidgetInbox()
        }
        return drained
    }

    private func read<Value: Decodable>(_ type: Value.Type, at url: URL) -> Value? {
        var value: Value?
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &error) { url in
            value = (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(Value.self, from: $0) }
        }
        return value
    }

    private func coordinate(writing url: URL, _ body: (URL) -> Void) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var error: NSError?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forMerging, error: &error, byAccessor: body)
    }
}
