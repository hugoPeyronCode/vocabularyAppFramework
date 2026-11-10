import SagaceUI
import Testing

struct LayoutWidthTests {
    @Test("iPhone, Split View un tiers et Slide Over gardent la mise en page iPhone", arguments: [320.0, 375, 393, 440, 599])
    func compact(width: Double) {
        #expect(LayoutWidth(width: width) == .compact)
    }

    @Test("iPad portrait, Split View moitié et sheets iPad s'élargissent", arguments: [600.0, 678, 744, 834, 999])
    func regular(width: Double) {
        #expect(LayoutWidth(width: width) == .regular)
        #expect(LayoutWidth(width: width).isRegular)
    }

    @Test("iPad paysage : deux colonnes", arguments: [1000.0, 1133, 1194, 1376])
    func wide(width: Double) {
        #expect(LayoutWidth(width: width) == .wide)
    }

    @Test("Une sheet iPad garde sa largeur, ou une marge de chaque côté dans une fenêtre plus étroite")
    func sheetWidth() {
        #expect(SagaceMetrics.sheetWidth(900, inWindow: 1194) == 900)
        #expect(SagaceMetrics.sheetWidth(900, inWindow: 834) == 754)
        #expect(SagaceMetrics.sheetWidth(700, inWindow: 834) == 700)
        #expect(SagaceMetrics.sheetWidth(700, inWindow: 0) == 700)
    }
}
