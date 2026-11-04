import AppIntents
import Foundation
import SagaceCore
import WidgetKit

// Gestes des widgets. Ils n'écrivent que dans la boîte d'envoi de l'App Group ; l'app les applique
// à sa prochaine ouverture (boîtes de Leitner, "À retenir"). WidgetKit recharge la frise après chaque geste.

/// Répondre à une révision depuis le widget.
struct AnswerReviewIntent: AppIntent {
    static let title: LocalizedStringResource = "Répondre à une révision"
    static let isDiscoverable = false

    @Parameter(title: "Fiche") var ficheID: String
    @Parameter(title: "Réponse") var choice: Int

    init() {}

    init(ficheID: String, choice: Int) {
        self.ficheID = ficheID
        self.choice = choice
    }

    func perform() async throws -> some IntentResult {
        guard let store = WidgetStore.shared, let review = store.readSnapshot()?.reviews.first(where: { $0.ficheID == ficheID }) else {
            return .result()
        }
        store.updateInbox { $0.answer(review, choice: choice, at: .now) }
        return .result()
    }
}

/// Après lecture de l'explication : révision suivante.
struct ContinueReviewIntent: AppIntent {
    static let title: LocalizedStringResource = "Continuer"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        WidgetStore.shared?.updateInbox { $0.continueReview() }
        return .result()
    }
}

/// "Suivante" sur le widget de fiche.
struct NextFicheIntent: AppIntent {
    static let title: LocalizedStringResource = "Fiche suivante"
    static let isDiscoverable = false

    @Parameter(title: "Widget") var key: String

    init() {}

    init(key: String) {
        self.key = key
    }

    func perform() async throws -> some IntentResult {
        WidgetStore.shared?.updateInbox { $0.nextCard(key: key, at: .now) }
        return .result()
    }
}

/// "À retenir" sur le widget de fiche.
struct SaveToLearnIntent: AppIntent {
    static let title: LocalizedStringResource = "À retenir"
    static let isDiscoverable = false

    @Parameter(title: "Fiche") var ficheID: String

    init() {}

    init(ficheID: String) {
        self.ficheID = ficheID
    }

    func perform() async throws -> some IntentResult {
        WidgetStore.shared?.updateInbox { $0.saveToLearn(ficheID, at: .now) }
        return .result()
    }
}

// MARK: Configuration du widget de fiche

enum FamilyOption: String, AppEnum {
    case toutes, paronyme, impropriete, passePartout, nuance, pleonasme, anglicisme, motMalCompris, expression

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Famille"
    static let caseDisplayRepresentations: [FamilyOption: DisplayRepresentation] = [
        .toutes: "Toutes les familles",
        .paronyme: "Paronymes",
        .impropriete: "Impropriétés",
        .passePartout: "Verbes passe-partout",
        .nuance: "Nuances",
        .pleonasme: "Pléonasmes",
        .anglicisme: "Anglicismes et faux amis",
        .motMalCompris: "Mots mal compris",
        .expression: "Expressions",
    ]

    var family: Family? { Family(rawValue: rawValue) }
}

enum RefreshOption: String, AppEnum {
    case daily, twiceDaily, hourly

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Rafraîchissement"
    static let caseDisplayRepresentations: [RefreshOption: DisplayRepresentation] = [
        .daily: "1 fois par jour",
        .twiceDaily: "2 fois par jour",
        .hourly: "Toutes les heures",
    ]

    var rate: RefreshRate { RefreshRate(rawValue: rawValue) ?? .daily }
}

/// Réglages du widget (WID-01), réservés au premium : en gratuit, toutes les familles, une fois par jour.
struct FicheWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Fiche du jour"
    static let description = IntentDescription("Une fiche sur votre écran d'accueil.")

    @Parameter(title: "Famille", default: .toutes) var famille: FamilyOption
    @Parameter(title: "Rafraîchissement", default: .daily) var rafraichissement: RefreshOption
    @Parameter(title: "Phrase d'auteur (grand widget)", default: true) var phraseAuteur: Bool
}
