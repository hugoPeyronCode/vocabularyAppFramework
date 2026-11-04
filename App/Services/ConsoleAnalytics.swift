import OSLog
import SagaceCore

/// Analytics en console, en attendant l'outil choisi en M7 (`OPEN_QUESTIONS.md` n° 5).
struct ConsoleAnalytics: Analytics {
    private let logger = Logger(subsystem: "com.cortex.VocabularyAppFramework", category: "analytics")

    func track(_ event: AnalyticsEvent) {
        let properties = event.properties.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        logger.info("\(event.name, privacy: .public) \(properties, privacy: .public)")
    }
}
