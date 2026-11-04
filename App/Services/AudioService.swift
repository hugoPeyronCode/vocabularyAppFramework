import AVFoundation

@MainActor
protocol Speaking: AnyObject {
    func speak(_ text: String)
}

/// Prononciation des mots avec une voix française de l'appareil (`03_ARCHITECTURE.md` section 1).
/// Le choix de la voix (VOI-01) arrive en M5 ; en attendant, la meilleure voix fr-FR disponible.
@MainActor
final class AudioService: Speaking {
    private let synthesizer = AVSpeechSynthesizer()
    var voiceIdentifier: String?

    func speak(_ text: String) {
        speak(text, with: voice)
    }

    /// Écoute d'une voix dans VOI-01.
    func preview(_ text: String, voiceIdentifier: String) {
        speak(text, with: AVSpeechSynthesisVoice(identifier: voiceIdentifier))
    }

    /// Voix françaises de l'appareil, les meilleures d'abord (VOI-01).
    static var frenchVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("fr") }
            .sorted { ($0.quality.rawValue, $0.language == "fr-FR" ? 1 : 0, $0.name) > ($1.quality.rawValue, $1.language == "fr-FR" ? 1 : 0, $1.name) }
    }

    private func speak(_ text: String, with voice: AVSpeechSynthesisVoice?) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }

    /// Voix choisie, sinon la meilleure voix fr-FR (Premium, puis Améliorée), sinon fr-CA.
    private var voice: AVSpeechSynthesisVoice? {
        if let voiceIdentifier, let chosen = AVSpeechSynthesisVoice(identifier: voiceIdentifier) { return chosen }
        return Self.frenchVoices.first ?? AVSpeechSynthesisVoice(language: "fr-FR")
    }
}
