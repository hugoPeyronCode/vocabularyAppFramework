import Foundation

// Mini mot croisé (Jeux). Grille, numérotation et saisie reprises du mot croisé de The Lexicon (BrainTrainer) ;
// la grille vient ici de `CrosswordBuilder`, à partir des fiches, jamais écrite en dur.

public enum CrosswordDirection: String, Codable, CaseIterable, Sendable {
    case across, down

    public var other: CrosswordDirection { self == .across ? .down : .across }
}

public struct GridPosition: Hashable, Comparable, Sendable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row; self.column = column
    }

    public func moved(_ direction: CrosswordDirection, by offset: Int = 1) -> GridPosition {
        switch direction {
        case .across: GridPosition(row: row, column: column + offset)
        case .down: GridPosition(row: row + offset, column: column)
        }
    }

    public static func < (lhs: GridPosition, rhs: GridPosition) -> Bool {
        (lhs.row, lhs.column) < (rhs.row, rhs.column)
    }
}

/// Une définition de la grille : réponse en capitales sans accents, définition courte de la fiche.
public struct CrosswordClue: Hashable, Sendable {
    public let number: Int
    public let direction: CrosswordDirection
    public let answer: String
    public let clue: String
    public let ficheID: String
}

public struct CrosswordPuzzle: Hashable, Sendable {
    public static let blackCell: Character = "#"

    /// Lignes de la grille, `#` pour une case noire.
    public let rows: [String]
    public let clues: [CrosswordClue]
}

public struct CrosswordSlot: Hashable, Sendable {
    public let number: Int
    public let direction: CrosswordDirection
    public let cells: [GridPosition]

    public var length: Int { cells.count }

    public func contains(_ position: GridPosition) -> Bool { cells.contains(position) }
}

public struct CrosswordGrid: Hashable, Sendable {
    public let solution: [[Character?]]
    public let numbers: [GridPosition: Int]
    public let slots: [CrosswordSlot]

    public init(rows: [String]) {
        let solution = rows.map { row in row.uppercased().map { $0 == CrosswordPuzzle.blackCell ? nil : Optional($0) } }
        self.solution = solution
        (numbers, slots) = Self.numberedSlots(in: solution)
    }

    public var rowCount: Int { solution.count }
    public var columnCount: Int { solution.map(\.count).max() ?? 0 }
    public var openPositions: [GridPosition] { allPositions.filter(isOpen) }

    /// Définitions dans l'ordre de lecture : horizontales puis verticales, par numéro.
    public var orderedSlots: [CrosswordSlot] {
        CrosswordDirection.allCases.flatMap { direction in
            slots.filter { $0.direction == direction }.sorted { $0.number < $1.number }
        }
    }

    public func isOpen(_ position: GridPosition) -> Bool { letter(at: position) != nil }

    public func letter(at position: GridPosition) -> Character? {
        guard solution.indices.contains(position.row), solution[position.row].indices.contains(position.column) else { return nil }
        return solution[position.row][position.column]
    }

    public func slot(containing position: GridPosition, direction: CrosswordDirection) -> CrosswordSlot? {
        slots.first { $0.direction == direction && $0.contains(position) }
    }

    public func letters(of slot: CrosswordSlot) -> String {
        String(slot.cells.compactMap(letter(at:)))
    }

    private var allPositions: [GridPosition] {
        solution.indices.flatMap { row in solution[row].indices.map { GridPosition(row: row, column: $0) } }
    }

    private static func numberedSlots(in solution: [[Character?]]) -> ([GridPosition: Int], [CrosswordSlot]) {
        var numbers: [GridPosition: Int] = [:]
        var slots: [CrosswordSlot] = []
        var nextNumber = 1
        for row in solution.indices {
            for column in solution[row].indices {
                let start = GridPosition(row: row, column: column)
                let starting = CrosswordDirection.allCases.compactMap { direction in
                    run(startingAt: start, direction: direction, in: solution).map { CrosswordSlot(number: nextNumber, direction: direction, cells: $0) }
                }
                guard !starting.isEmpty else { continue }
                numbers[start] = nextNumber
                slots.append(contentsOf: starting)
                nextNumber += 1
            }
        }
        return (numbers, slots)
    }

    private static func run(startingAt start: GridPosition, direction: CrosswordDirection, in solution: [[Character?]]) -> [GridPosition]? {
        let isOpen: (GridPosition) -> Bool = { position in
            solution.indices.contains(position.row) && solution[position.row].indices.contains(position.column)
                && solution[position.row][position.column] != nil
        }
        guard isOpen(start), !isOpen(start.moved(direction, by: -1)) else { return nil }
        var cells: [GridPosition] = []
        var position = start
        while isOpen(position) {
            cells.append(position)
            position = position.moved(direction)
        }
        return cells.count >= Rules.crosswordMinWordLength ? cells : nil
    }
}

/// Partie en cours : saisie, case et sens courants, indices, vérification.
public struct CrosswordEngine: Sendable {
    public let puzzle: CrosswordPuzzle
    public let grid: CrosswordGrid
    public private(set) var entries: [GridPosition: Character] = [:]
    public private(set) var revealed: Set<GridPosition> = []
    public private(set) var hintsUsed = 0
    public private(set) var currentPosition: GridPosition
    public private(set) var direction: CrosswordDirection

    public init(puzzle: CrosswordPuzzle) {
        self.puzzle = puzzle
        let grid = CrosswordGrid(rows: puzzle.rows)
        self.grid = grid
        let first = grid.orderedSlots.first
        currentPosition = first?.cells.first ?? GridPosition(row: 0, column: 0)
        direction = first?.direction ?? .across
    }

    public var currentSlot: CrosswordSlot? { grid.slot(containing: currentPosition, direction: direction) }
    public var currentClue: CrosswordClue? { currentSlot.flatMap(clue(for:)) }
    public var isFull: Bool { grid.openPositions.allSatisfy { entries[$0] != nil } }
    public var isSolved: Bool { grid.openPositions.allSatisfy { entries[$0] == grid.letter(at: $0) } }

    public func clue(for slot: CrosswordSlot) -> CrosswordClue? {
        puzzle.clues.first { $0.number == slot.number && $0.direction == slot.direction }
    }

    public func entry(at position: GridPosition) -> Character? { entries[position] }
    public func number(at position: GridPosition) -> Int? { grid.numbers[position] }
    public func isInCurrentSlot(_ position: GridPosition) -> Bool { currentSlot?.contains(position) ?? false }

    /// Toucher une case : la sélectionne ; toucher la case courante change de sens.
    public mutating func tap(_ position: GridPosition) {
        guard grid.isOpen(position) else { return }
        if position == currentPosition {
            toggleDirection()
            return
        }
        currentPosition = position
        if grid.slot(containing: position, direction: direction) == nil { direction = direction.other }
    }

    public mutating func toggleDirection() {
        guard grid.slot(containing: currentPosition, direction: direction.other) != nil else { return }
        direction = direction.other
    }

    public mutating func nextClue() { moveClue(by: 1) }
    public mutating func previousClue() { moveClue(by: -1) }

    public mutating func select(_ slot: CrosswordSlot) {
        direction = slot.direction
        currentPosition = slot.cells.first { entries[$0] == nil } ?? slot.cells[0]
    }

    /// Une lettre, accents ignorés ("é" compte pour "E").
    public mutating func type(_ letter: Character) {
        guard grid.isOpen(currentPosition), let folded = CrosswordBuilder.fold(String(letter)).first, folded.isLetter else { return }
        entries[currentPosition] = folded
        advance()
    }

    public mutating func delete() {
        if entries[currentPosition] != nil {
            entries[currentPosition] = nil
            return
        }
        guard let slot = currentSlot, let index = slot.cells.firstIndex(of: currentPosition), index > 0 else { return }
        currentPosition = slot.cells[index - 1]
        entries[currentPosition] = nil
    }

    public func wrongPositions() -> Set<GridPosition> {
        Set(grid.openPositions.filter { position in entries[position].map { $0 != grid.letter(at: position) } ?? false })
    }

    /// Indice : une lettre juste dans la définition courante.
    @discardableResult
    public mutating func revealHint() -> GridPosition? {
        let target = isCorrect(currentPosition) ? currentSlot?.cells.first { !isCorrect($0) } : currentPosition
        guard let target, let letter = grid.letter(at: target) else { return nil }
        entries[target] = letter
        revealed.insert(target)
        hintsUsed += 1
        return target
    }

    public mutating func revealAll() {
        for position in grid.openPositions where !isCorrect(position) {
            entries[position] = grid.letter(at: position)
            revealed.insert(position)
        }
    }

    private func isCorrect(_ position: GridPosition) -> Bool { entries[position] == grid.letter(at: position) }

    private mutating func advance() {
        guard let slot = currentSlot, let index = slot.cells.firstIndex(of: currentPosition) else { return }
        let following = slot.cells[(index + 1)...]
        let preceding = slot.cells[..<index]
        if let empty = following.first(where: { entries[$0] == nil }) ?? preceding.first(where: { entries[$0] == nil }) {
            currentPosition = empty
        } else if let next = following.first {
            currentPosition = next
        }
    }

    private mutating func moveClue(by offset: Int) {
        let slots = grid.orderedSlots
        guard !slots.isEmpty else { return }
        let index = currentSlot.flatMap { slots.firstIndex(of: $0) } ?? 0
        select(slots[(index + offset + slots.count) % slots.count])
    }
}
