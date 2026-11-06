import Foundation

/// Conteneur partagé entre l'app et ses widgets : base SwiftData, snapshot et boîte d'envoi des widgets.
public enum AppGroup {
    public static let identifier = "group.com.cortex.VocabularyAppFramework"

    /// Dossier du conteneur partagé, `nil` si l'entitlement App Group manque.
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
