import Foundation
import SagaceCore
import SwiftData

/// Conteneur SwiftData de l'app, partagé avec les widgets par l'App Group.
public enum SagaceStore {
    public static let schema = Schema([
        UserProfile.self, Preferences.self, FicheState.self, UserCollection.self, OwnWord.self,
        PracticeSession.self, PracticeAnswer.self, LevelTestResult.self, ActivityDay.self,
        Reminder.self, WidgetConfig.self, ErrorReport.self, Achievement.self,
    ])

    /// Base dans le conteneur de l'App Group, ou en mémoire pour les tests et les aperçus.
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let url = AppGroup.containerURL?.appending(path: "Library/Application Support/Sagace.store") {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            configuration = ModelConfiguration(schema: schema, url: url)
        } else {
            configuration = ModelConfiguration(schema: schema)
        }
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
