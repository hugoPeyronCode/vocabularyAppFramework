import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI

/// Mini mot croisé (Jeux) : une grille de 3 à 5 mots tirée des fiches déjà vues d'abord, la définition courte
/// pour indice. Compte comme une session de jeu (limite gratuite).
@MainActor @Observable
final class CrosswordViewModel {
    enum Phase: Equatable { case playing, solved, locked, empty }

    enum Highlight: Equatable { case none, slot, current, wrong, solved, revealed }

    struct Cell: Identifiable, Equatable {
        let position: GridPosition
        let isOpen: Bool
        let number: Int?
        let letter: Character?
        let highlight: Highlight
        var id: GridPosition { position }
    }

    /// Mot de la grille, montré une fois la grille finie, avec sa définition.
    struct Word: Identifiable, Equatable {
        let ficheID: String
        let headword: String
        let definition: String
        let wasRevealed: Bool
        var id: String { ficheID }
    }

    private(set) var phase: Phase = .playing
    private(set) var engine: CrosswordEngine?
    private(set) var wrongCells: Set<GridPosition> = []
    /// Incrémenté à chaque vérification ratée (secousse de la grille).
    private(set) var shakes = 0
    private(set) var savedToLearn: Set<String> = []
    private(set) var gaveUp = false

    private let content: ContentRepository
    private let recorder: any PracticeRecording
    private let progress: any ProgressStoring
    private let entitlements: any PremiumProviding
    private let haptics: any HapticPlaying
    private let analytics: any Analytics
    private let now: () -> Date
    private var session: PracticeSession?
    private var seedOffset: UInt64 = 0
    private var flash: Task<Void, Never>?

    init(content: ContentRepository, recorder: any PracticeRecording, progress: any ProgressStoring, entitlements: any PremiumProviding,
         haptics: any HapticPlaying, analytics: any Analytics, now: @escaping () -> Date) {
        self.content = content; self.recorder = recorder; self.progress = progress; self.entitlements = entitlements
        self.haptics = haptics; self.analytics = analytics; self.now = now
    }

    var isInProgress: Bool { phase == .playing && engine != nil }

    func start() {
        guard PracticeStats.canStartGame(isPremium: entitlements.isPremium, gameSessionsToday: recorder.gameSessionsToday(at: now())) else {
            phase = .locked
            return
        }
        // Les fiches déjà vues d'abord : la grille fait retrouver des mots rencontrés dans le feed.
        let seen = Set(progress.allProgress().keys)
        let pool = content.fiches.filter { seen.contains($0.id) } + content.fiches.filter { !seen.contains($0.id) }
        let seed = UInt64(bitPattern: Int64(now().timeIntervalSinceReferenceDate)) &+ seedOffset
        guard let puzzle = CrosswordBuilder().build(from: pool, seed: seed) else {
            phase = .empty
            return
        }
        engine = CrosswordEngine(puzzle: puzzle)
        wrongCells = []
        savedToLearn = []
        gaveUp = false
        phase = .playing
        session = recorder.start(.crossword, at: now())
        analytics.track(.practiceStarted(mode: .crossword))
    }

    func replay() {
        seedOffset &+= 1
        start()
    }

    // MARK: Grille

    var rowCount: Int { engine?.grid.rowCount ?? 0 }
    var columnCount: Int { engine?.grid.columnCount ?? 0 }

    var cells: [Cell] {
        guard let engine else { return [] }
        return (0..<engine.grid.rowCount).flatMap { row in
            (0..<engine.grid.columnCount).map { column in
                let position = GridPosition(row: row, column: column)
                let isOpen = engine.grid.isOpen(position)
                return Cell(position: position, isOpen: isOpen, number: engine.number(at: position),
                            letter: engine.entry(at: position), highlight: isOpen ? highlight(at: position, in: engine) : .none)
            }
        }
    }

    private func highlight(at position: GridPosition, in engine: CrosswordEngine) -> Highlight {
        if phase == .solved { return engine.revealed.contains(position) ? .revealed : .solved }
        if wrongCells.contains(position) { return .wrong }
        if position == engine.currentPosition { return .current }
        if engine.isInCurrentSlot(position) { return .slot }
        return .none
    }

    var clueNumber: Int? { engine?.currentSlot?.number }
    var clueIsAcross: Bool { engine?.currentSlot?.direction == .across }
    var clueText: String { engine?.currentClue?.clue ?? "" }
    var clueLength: Int { engine?.currentSlot?.length ?? 0 }
    var isFull: Bool { engine?.isFull ?? false }
    var canReveal: Bool { shakes > 0 }

    // MARK: Saisie

    func tap(_ position: GridPosition) {
        guard phase == .playing else { return }
        engine?.tap(position)
        haptics.play(.selection)
    }

    func type(_ letter: Character) {
        guard phase == .playing, var engine else { return }
        let slot = engine.currentSlot
        engine.type(letter)
        self.engine = engine
        wrongCells = []
        let completesWord = slot.map { slot in slot.cells.allSatisfy { engine.entry(at: $0) != nil } } ?? false
        haptics.play(completesWord ? .light : .selection)
        if engine.isSolved { finish() }
    }

    func delete() {
        guard phase == .playing else { return }
        engine?.delete()
        wrongCells = []
        haptics.play(.selection)
    }

    func nextClue() {
        engine?.nextClue()
        haptics.play(.selection)
    }

    func previousClue() {
        engine?.previousClue()
        haptics.play(.selection)
    }

    /// Indice : une lettre juste dans la définition courante.
    func hint() {
        guard phase == .playing else { return }
        engine?.revealHint()
        haptics.play(.light)
        if engine?.isSolved == true { finish() }
    }

    /// Vérifier une grille pleine : les cases fausses clignotent.
    func check() {
        guard phase == .playing, let engine else { return }
        let wrong = engine.wrongPositions()
        guard !wrong.isEmpty else {
            finish()
            return
        }
        wrongCells = wrong
        shakes += 1
        haptics.play(.error)
        flash?.cancel()
        flash = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            self?.wrongCells = []
        }
    }

    /// Révéler la grille (après une vérification ratée) : la partie se termine.
    func reveal() {
        guard phase == .playing else { return }
        gaveUp = true
        engine?.revealAll()
        wrongCells = []
        haptics.play(.light)
        finish()
    }

    private func finish() {
        guard phase == .playing, let engine else { return }
        phase = .solved
        let total = engine.puzzle.clues.count
        let found = words.filter { !$0.wasRevealed }.count
        if let session { recorder.finish(session, score: found, total: total, at: now()) }
        analytics.track(.practiceCompleted(mode: .crossword, score: found, total: total))
        haptics.play(gaveUp ? .soft : .celebration)
    }

    // MARK: Résultat

    var words: [Word] {
        guard let engine else { return [] }
        return engine.puzzle.clues.compactMap { clue in
            guard let slot = engine.grid.slots.first(where: { $0.number == clue.number && $0.direction == clue.direction }) else { return nil }
            let headword = content.fiche(id: clue.ficheID)?.headword ?? clue.answer.lowercased()
            return Word(ficheID: clue.ficheID, headword: headword, definition: clue.clue,
                        wasRevealed: slot.cells.contains { engine.revealed.contains($0) })
        }
    }

    var foundCount: Int { words.filter { !$0.wasRevealed }.count }

    func saveToLearn(_ ficheID: String) {
        guard !savedToLearn.contains(ficheID) else { return }
        _ = progress.sort(ficheID, as: .toLearn, at: now())
        savedToLearn.insert(ficheID)
        haptics.play(.light)
    }
}
