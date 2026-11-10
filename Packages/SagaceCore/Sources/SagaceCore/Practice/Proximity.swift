import Foundation

/// Proximité entre deux mots, par la forme ou par le sens. Sert à choisir des mauvaises réponses qui ressemblent
/// à la bonne (un lien d'orthographe ou de sens), pour que les questions ne soient pas triviales.
public enum Proximity {
    /// Mot réduit à sa forme comparable : sans casse ni accents, sans pronom réfléchi ("se rappeler" → "rappeler").
    public static func core(_ word: String) -> String {
        var text = SearchIndex.normalize(word)
        for prefix in ["se ", "s'", "s’"] where text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
        }
        return text
    }

    /// Proximité de forme, de 0 à 1 : distance d'édition relative, début ou fin de mot partagés
    /// ("éminent" / "imminent", "prolongation" / "prolongement").
    public static func form(_ a: String, _ b: String) -> Double {
        form(Array(core(a)), Array(core(b)))
    }

    /// Formes déjà normalisées par l'index de questions.
    static func form(_ a: [Character], _ b: [Character]) -> Double {
        guard !a.isEmpty, !b.isEmpty, a != b else { return a == b ? 1 : 0 }
        let edit = 1 - Double(levenshtein(a, b)) / Double(max(a.count, b.count))
        let prefix = zip(a, b).prefix { $0 == $1 }.count
        let suffix = zip(a.reversed(), b.reversed()).prefix { $0 == $1 }.count
        let shorter = Double(min(a.count, b.count))
        let byPrefix = prefix >= Rules.proximityMinAffix ? 0.9 * Double(prefix) / shorter : 0
        let bySuffix = suffix >= Rules.proximityMinAffix + 1 ? 0.6 * Double(suffix) / shorter : 0
        return max(edit, byPrefix, bySuffix)
    }

    /// Mots pleins d'un texte, tronqués à une racine grossière ("souvenirs" et "souvenir" se rejoignent).
    public static func keywords(_ text: String) -> Set<String> {
        let words = SearchIndex.normalize(text)
            .split { !$0.isLetter }
            .map(String.init)
            .filter { $0.count >= Rules.proximityMinKeywordLength && !stopWords.contains($0) }
        return Set(words.map { String($0.prefix(Rules.proximityStemLength)) })
    }

    /// Proximité de sens, de 0 à 1 : part des mots pleins partagés.
    public static func meaning(_ a: Set<String>, _ b: Set<String>) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        return Double(a.intersection(b).count) / Double(min(a.count, b.count))
    }

    static func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        var previous = Array(0...b.count)
        var current = Array(repeating: 0, count: b.count + 1)
        for (i, ca) in a.enumerated() {
            current[0] = i + 1
            for (j, cb) in b.enumerated() {
                current[j + 1] = min(previous[j + 1] + 1, current[j] + 1, previous[j] + (ca == cb ? 0 : 1))
            }
            swap(&previous, &current)
        }
        return previous[b.count]
    }

    /// Mots trop courants pour dire quelque chose du sens.
    private static let stopWords: Set<String> = [
        "avec", "dans", "pour", "sans", "sous", "vers", "chez", "entre", "elle", "elles", "nous", "vous", "leur", "leurs",
        "cette", "celui", "celle", "ceux", "dont", "mais", "donc", "plus", "moins", "tres", "bien", "tout", "toute",
        "tous", "toutes", "autre", "autres", "comme", "quelque", "quelqu", "chose", "choses", "faire", "etre", "avoir",
        "rendre", "mettre", "aussi", "meme", "encore", "alors", "ainsi", "parce", "lorsqu", "quand", "personne",
    ]
}
