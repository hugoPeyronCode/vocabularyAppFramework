import Foundation

/// Liens légaux du paywall et de "À propos".
enum AppLinks {
    /// Contrat de licence standard d'Apple, en attendant des conditions propres (`OPEN_QUESTIONS.md` n° 10).
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
    /// Politique de confidentialité : URL à définir (`OPEN_QUESTIONS.md` n° 10). Le lien est masqué tant qu'elle manque.
    static let privacy: URL? = nil
    /// "Envoyer un avis" : adresse à définir ; la ligne du profil est masquée tant qu'elle manque.
    static let feedback: URL? = nil
}
