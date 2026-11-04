import Foundation
import Testing
@testable import SagaceCore

@Suite("Mot croisé")
struct CrosswordTests {
    private let words = ["pallier", "prévoir", "empêcher", "toucher", "emmener", "apporter", "regarder", "instaurer",
                         "éminent", "résoudre", "déceler", "prononcer", "acronyme", "problème", "achalandé"]
        .map { Fiche.word($0, meaning: "Définition de \($0)") }

    @Test("Grille construite : chaque mot est une définition, aucune suite de lettres sans définition", arguments: 0..<20)
    func wellFormed(seed: UInt64) throws {
        let puzzle = try #require(CrosswordBuilder().build(from: words, seed: seed))
        let grid = CrosswordGrid(rows: puzzle.rows)
        #expect((Rules.crosswordMinWordCount...Rules.crosswordWordCount).contains(puzzle.clues.count))
        #expect(grid.slots.count == puzzle.clues.count)
        #expect(grid.rowCount <= Rules.crosswordMaxSide && grid.columnCount <= Rules.crosswordMaxSide)
        for clue in puzzle.clues {
            let slot = try #require(grid.slots.first { $0.number == clue.number && $0.direction == clue.direction })
            #expect(grid.letters(of: slot) == clue.answer)
            #expect(clue.clue == "Définition de \(words.first { $0.id == clue.ficheID }!.headword)")
        }
    }

    @Test("Même graine, même grille")
    func deterministic() {
        #expect(CrosswordBuilder().build(from: words, seed: 7) == CrosswordBuilder().build(from: words, seed: 7))
    }

    @Test("Réponses : un seul mot, sans accents, longueur admise")
    func answers() {
        #expect(CrosswordBuilder.answer(for: .word("prévoir")) == "PREVOIR")
        #expect(CrosswordBuilder.answer(for: .word("instaurer")) == nil)
        #expect(CrosswordBuilder.answer(for: .word("éminent")) == "EMINENT")
        #expect(CrosswordBuilder.answer(for: .word("se rappeler")) == nil)
        #expect(CrosswordBuilder.answer(for: .word("au temps pour moi")) == nil)
        #expect(CrosswordBuilder.answer(for: .word("as")) == nil)
    }

    @Test("Pas assez de mots : pas de grille")
    func tooFew() {
        #expect(CrosswordBuilder().build(from: Array(words.prefix(2)), seed: 1) == nil)
    }

    @Test("Saisie : accents ignorés, avance dans la définition, grille résolue")
    func solve() throws {
        let puzzle = try #require(CrosswordBuilder().build(from: words, seed: 3))
        var engine = CrosswordEngine(puzzle: puzzle)
        for slot in engine.grid.orderedSlots {
            engine.select(slot)
            for position in slot.cells {
                engine.tap(position)
                if engine.currentSlot != slot { engine.toggleDirection() }
                let letter = engine.grid.letter(at: position)!
                engine.type(letter == "E" ? "é" : Character(letter.lowercased()))
            }
        }
        #expect(engine.isFull)
        #expect(engine.wrongPositions().isEmpty)
        #expect(engine.isSolved)
    }

    @Test("Erreurs repérées, indice puis révélation")
    func hintsAndReveal() throws {
        let puzzle = try #require(CrosswordBuilder().build(from: words, seed: 5))
        var engine = CrosswordEngine(puzzle: puzzle)
        let start = engine.currentPosition
        let wrong: Character = engine.grid.letter(at: start) == "Z" ? "Y" : "Z"
        engine.type(wrong)
        #expect(engine.wrongPositions() == [start])
        engine.tap(start)
        engine.tap(start)
        #expect(engine.revealHint() != nil)
        #expect(engine.hintsUsed == 1)
        engine.revealAll()
        #expect(engine.isSolved)
    }

    @Test("Sur les fiches modèles, une grille de 3 mots au moins")
    func seedPack() throws {
        let repository = try ContentRepository(data: Data(contentsOf: SeedContent.fichesURL), visibility: .development)
        let puzzle = try #require(CrosswordBuilder().build(from: repository.fiches, seed: 1))
        #expect(puzzle.clues.count >= Rules.crosswordMinWordCount)
    }
}
