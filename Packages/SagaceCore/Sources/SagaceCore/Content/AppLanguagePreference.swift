import Foundation

/// Choix explicite commun à l'interface, au contenu et aux widgets. Aucun changement de progression.
public enum AppLanguagePreference: String, CaseIterable, Sendable {
    case automatic, fr, en

    public static let defaultsKey = "sagace.appLanguage"
    public static var sharedDefaults: UserDefaults { UserDefaults(suiteName: AppGroup.identifier) ?? .standard }

    public static func saved(in defaults: UserDefaults = sharedDefaults) -> Self {
        defaults.string(forKey: defaultsKey).flatMap(Self.init(rawValue:)) ?? .automatic
    }

    public func save(in defaults: UserDefaults = sharedDefaults) {
        defaults.set(rawValue, forKey: Self.defaultsKey)
    }

    public func resolved(preferredLanguages: [String] = Locale.preferredLanguages, englishPackAvailable: Bool = true) -> Language {
        switch self {
        case .automatic: ContentLanguage.preferred(preferredLanguages, englishPackAvailable: englishPackAvailable)
        case .fr: .fr
        case .en: englishPackAvailable ? .en : .fr
        }
    }

    public var locale: Locale { Locale(identifier: resolved().rawValue) }
}
