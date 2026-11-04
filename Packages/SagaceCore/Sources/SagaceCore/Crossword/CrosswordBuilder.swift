import Foundation

/// Construit une mini grille de mots croisés à partir des fiches : mots d'un seul tenant, en capitales sans accents,
/// la définition courte pour indice. Placement glouton (chaque mot croise au moins un mot déjà posé, aucune case
/// ne touche un autre mot hors croisement), plusieurs essais, la grille la plus riche gagne. Déterministe à graine égale.
public struct CrosswordBuilder: Sendable {
    private struct Placement {
        let fiche: Fiche
        let answer: [Character]
        let start: GridPosition
        let direction: CrosswordDirection

        var cells: [GridPosition] { answer.indices.map { start.moved(direction, by: $0) } }
    }

    private struct Board {
        var letters: [GridPosition: Character] = [:]
        var directions: [GridPosition: Set<CrosswordDirection>] = [:]
        var placements: [Placement] = []
        var crossings = 0

        var bounds: (minRow: Int, maxRow: Int, minColumn: Int, maxColumn: Int) {
            let rows = letters.keys.map(\.row), columns = letters.keys.map(\.column)
            return (rows.min() ?? 0, rows.max() ?? 0, columns.min() ?? 0, columns.max() ?? 0)
        }

        /// Nombre de croisements si le mot peut être posé là, `nil` sinon.
        func crossings(for answer: [Character], at start: GridPosition, _ direction: CrosswordDirection) -> Int? {
            if letters[start.moved(direction, by: -1)] != nil || letters[start.moved(direction, by: answer.count)] != nil { return nil }
            var crossings = 0
            var cells: [GridPosition] = []
            for (offset, letter) in answer.enumerated() {
                let position = start.moved(direction, by: offset)
                cells.append(position)
                if let existing = letters[position] {
                    guard existing == letter, directions[position]?.contains(direction) != true else { return nil }
                    crossings += 1
                } else if letters[position.moved(direction.other, by: -1)] != nil || letters[position.moved(direction.other, by: 1)] != nil {
                    return nil
                }
            }
            let rows = letters.keys.map(\.row) + cells.map(\.row), columns = letters.keys.map(\.column) + cells.map(\.column)
            guard (rows.max()! - rows.min()! + 1) <= Rules.crosswordMaxSide,
                  (columns.max()! - columns.min()! + 1) <= Rules.crosswordMaxSide else { return nil }
            return crossings
        }

        mutating func place(_ placement: Placement, crossings: Int) {
            for (position, letter) in zip(placement.cells, placement.answer) {
                letters[position] = letter
                directions[position, default: []].insert(placement.direction)
            }
            placements.append(placement)
            self.crossings += crossings
        }
    }

    public init() {}

    /// Capitales sans accents ni ligatures ("Œuvre" → "OEUVRE").
    public static func fold(_ text: String) -> String {
        text.replacingOccurrences(of: "œ", with: "oe").replacingOccurrences(of: "Œ", with: "OE")
            .replacingOccurrences(of: "æ", with: "ae").replacingOccurrences(of: "Æ", with: "AE")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr"))
            .uppercased()
    }

    /// Réponse possible pour une fiche : un seul mot, lettres seules, longueur admise.
    public static func answer(for fiche: Fiche) -> String? {
        let answer = fold(fiche.headword)
        guard answer.allSatisfy({ $0.isASCII && $0.isLetter }), Rules.crosswordWordLength.contains(answer.count) else { return nil }
        return answer
    }

    /// Grille de `Rules.crosswordWordCount` mots au plus, `nil` si le réservoir ne permet pas d'en croiser assez.
    /// - Parameter pool: fiches à faire jouer, les premières d'abord (par exemple les fiches déjà vues).
    public func build(from pool: [Fiche], seed: UInt64) -> CrosswordPuzzle? {
        var seen = Set<String>()
        let candidates = pool.compactMap { fiche -> (Fiche, [Character])? in
            guard let answer = Self.answer(for: fiche), seen.insert(answer).inserted else { return nil }
            return (fiche, Array(answer))
        }
        guard candidates.count >= Rules.crosswordMinWordCount else { return nil }
        var rng = SeededGenerator(seed: seed)
        var best: Board?
        for _ in 0..<Rules.crosswordAttempts {
            let board = attempt(with: candidates.shuffled(using: &rng), rng: &rng)
            if best.map({ (board.placements.count, board.crossings) > ($0.placements.count, $0.crossings) }) ?? true {
                best = board
            }
            if best?.placements.count == Rules.crosswordWordCount { break }
        }
        guard let best, best.placements.count >= Rules.crosswordMinWordCount else { return nil }
        return puzzle(from: best)
    }

    private func attempt(with candidates: [(Fiche, [Character])], rng: inout SeededGenerator) -> Board {
        var board = Board()
        guard let (first, answer) = candidates.first(where: { $0.1.count >= Rules.crosswordWordLength.upperBound - 2 }) ?? candidates.first else { return board }
        board.place(Placement(fiche: first, answer: answer, start: GridPosition(row: 0, column: 0), direction: .across), crossings: 0)
        for (fiche, answer) in candidates where fiche.id != first.id && board.placements.count < Rules.crosswordWordCount {
            var options: [(Placement, Int)] = []
            for (position, letter) in board.letters {
                for (offset, candidate) in answer.enumerated() where candidate == letter {
                    for direction in CrosswordDirection.allCases {
                        let start = position.moved(direction, by: -offset)
                        if let crossings = board.crossings(for: answer, at: start, direction), crossings > 0 {
                            options.append((Placement(fiche: fiche, answer: answer, start: start, direction: direction), crossings))
                        }
                    }
                }
            }
            let most = options.map(\.1).max() ?? 0
            let preferred = options.filter { $0.1 == most }.sorted { $0.0.start < $1.0.start || ($0.0.start == $1.0.start && $0.0.direction == .across) }
            if !preferred.isEmpty {
                let (placement, crossings) = preferred[Int(rng.next() % UInt64(preferred.count))]
                board.place(placement, crossings: crossings)
            }
        }
        return board
    }

    private func puzzle(from board: Board) -> CrosswordPuzzle {
        let bounds = board.bounds
        let rows = (bounds.minRow...bounds.maxRow).map { row in
            String((bounds.minColumn...bounds.maxColumn).map { column in
                board.letters[GridPosition(row: row, column: column)] ?? CrosswordPuzzle.blackCell
            })
        }
        let grid = CrosswordGrid(rows: rows)
        let clues = board.placements.compactMap { placement -> CrosswordClue? in
            let cells = placement.cells.map { GridPosition(row: $0.row - bounds.minRow, column: $0.column - bounds.minColumn) }
            guard let slot = grid.slots.first(where: { $0.direction == placement.direction && $0.cells == cells }) else { return nil }
            return CrosswordClue(number: slot.number, direction: slot.direction, answer: String(placement.answer),
                                 clue: placement.fiche.shortDefinition, ficheID: placement.fiche.id)
        }
        .sorted { ($0.direction == .across ? 0 : 1, $0.number) < ($1.direction == .across ? 0 : 1, $1.number) }
        return CrosswordPuzzle(rows: rows, clues: clues)
    }
}
