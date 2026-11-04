import Foundation

/// Problème de conformité d'une fiche au schéma `content/schema/fiche.schema.json`
/// et aux contrôles automatiques de `05_CONTENT.md` section 3.4.
public struct FicheIssue: Hashable, Sendable, CustomStringConvertible {
    public let ficheID: String
    public let field: String
    public let message: String

    public var description: String { "\(ficheID) · \(field) : \(message)" }
}

/// Contrôles structurels d'un pack de fiches. Pure et sans effet de bord.
public enum FicheValidator {

    public static func validate(_ fiches: [Fiche]) -> [FicheIssue] {
        var issues = fiches.flatMap(validate)
        var seenIDs = Set<String>()
        var seenHeadwords = Set<String>()
        for fiche in fiches {
            if !seenIDs.insert(fiche.id).inserted {
                issues.append(FicheIssue(ficheID: fiche.id, field: "id", message: "identifiant en double"))
            }
            let key = "\(fiche.family.rawValue)|\(fiche.headword.lowercased())"
            if !seenHeadwords.insert(key).inserted {
                issues.append(FicheIssue(ficheID: fiche.id, field: "headword", message: "mot en double dans la famille"))
            }
        }
        return issues
    }

    public static func validate(_ fiche: Fiche) -> [FicheIssue] {
        var issues: [FicheIssue] = []
        func fail(_ field: String, _ message: String) {
            issues.append(FicheIssue(ficheID: fiche.id, field: field, message: message))
        }

        if fiche.id.wholeMatch(of: /(fr|en)\.[a-z0-9_]+/) == nil { fail("id", "format attendu fr.mot_compose") }
        if !fiche.id.hasPrefix(fiche.language.rawValue + ".") { fail("id", "préfixe différent de la langue") }
        if fiche.headword.isEmpty { fail("headword", "vide") }
        if fiche.partOfSpeech == .nom && fiche.gender == nil { fail("gender", "obligatoire pour un nom") }
        if fiche.phonetic.wholeMatch(of: /\/.+\//) == nil { fail("phonetic", "doit être entre barres obliques") }

        let short = fiche.shortDefinition
        if short.count < 5 || short.count > Rules.shortDefinitionMaxLength {
            fail("shortDefinition", "\(short.count) caractères, attendu 5 à \(Rules.shortDefinitionMaxLength)")
        }
        if short.hasSuffix(".") { fail("shortDefinition", "sans point final") }
        if fiche.definition.count < 5 { fail("definition", "trop courte") }

        if let usage = fiche.usage, usage.explanation.count > Rules.usageExplanationMaxLength {
            fail("usage.explanation", "plus de \(Rules.usageExplanationMaxLength) caractères")
        }
        if let nuance = fiche.nuance, nuance.count > Rules.nuanceMaxLength {
            fail("nuance", "plus de \(Rules.nuanceMaxLength) caractères")
        }

        if !Rules.examplesRange.contains(fiche.examples.count) { fail("examples", "2 ou 3 exemples attendus") }
        for example in fiche.examples where example.firstMatch(of: /\*\*.+\*\*/) == nil {
            fail("examples", "le mot doit être entre ** ** : \(example)")
        }

        if let quote = fiche.authorQuote, !quote.url.hasPrefix("https://fr.wikisource.org/") {
            fail("authorQuote.url", "doit pointer vers fr.wikisource.org")
        }

        if fiche.difficulty == nil { fail("level", "attendu 1 à 5") }

        if fiche.quiz.isEmpty { fail("quiz", "au moins une question") }
        for (index, item) in fiche.quiz.enumerated() {
            let field = "quiz[\(index)]"
            if !Rules.quizChoicesRange.contains(item.choices.count) { fail(field, "2 ou 3 choix attendus") }
            if !item.choices.indices.contains(item.answerIndex) { fail(field, "answerIndex hors des choix") }
            if Set(item.choices).count != item.choices.count { fail(field, "choix en double") }
            if item.explanation.count > Rules.quizExplanationMaxLength {
                fail(field, "explication de plus de \(Rules.quizExplanationMaxLength) caractères")
            }
            let wrong = item.choices.enumerated().filter { $0.offset != item.answerIndex }.map(\.element)
            if wrong.contains(where: fiche.synonyms.contains) { fail(field, "un synonyme est proposé comme mauvaise réponse") }
        }

        if fiche.sources.isEmpty { fail("sources", "au moins une source") }
        if !fiche.sources.contains(where: { $0.url.hasPrefix("http") }) { fail("sources", "au moins une source avec URL") }

        return issues
    }
}
