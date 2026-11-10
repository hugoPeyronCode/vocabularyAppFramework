import Foundation
import SagaceCore

/// Les chaînes produites hors de SwiftUI doivent recevoir la même langue que son environnement.
enum AppLocalization {
    static func string(_ resource: LocalizedStringResource, locale: Locale = AppLanguagePreference.saved().locale) -> String {
        var resource = resource
        resource.locale = locale
        return String(localized: resource)
    }
}

enum AppContent {
    static func load(_ language: Language, visibility: ContentRepository.Visibility) async throws -> (ContentRepository, Topics) {
        let directory = "Content/\(language.rawValue)"
        guard let fichesURL = Bundle.main.url(forResource: "fiches", withExtension: "json", subdirectory: directory),
              let topicsURL = Bundle.main.url(forResource: "topics", withExtension: "json", subdirectory: directory) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let content = try await ContentRepository.load(contentsOf: fichesURL, visibility: visibility)
        let topics = try JSONDecoder().decode(Topics.self, from: Data(contentsOf: topicsURL))
        return (content, topics)
    }
}
