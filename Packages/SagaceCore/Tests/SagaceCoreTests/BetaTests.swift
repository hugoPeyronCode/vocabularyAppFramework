import Foundation
import Testing
@testable import SagaceCore

@Suite("Bêta TestFlight")
struct BetaTests {
    @Test("Brouillons et boutons de relecture : développement et TestFlight, jamais l'App Store")
    func channels() {
        #expect(DistributionChannel.appStore.contentVisibility == .production)
        #expect(DistributionChannel.testFlight.contentVisibility == .development)
        #expect(DistributionChannel.development.contentVisibility == .development)
        #expect(!DistributionChannel.appStore.showsBetaReview)
        #expect(DistributionChannel.testFlight.showsBetaReview)
    }

    @Test("Export CSV : en-tête, ordre chronologique, champs échappés")
    func csv() {
        let early = Date(timeIntervalSince1970: 1_800_000_000)
        let entries = [
            ReviewExport.Entry(ficheID: "fr.pallier", headword: "pallier", reason: .definition, comment: "Il manque \"un\" sens,\nvoir Littré", createdAt: early.addingTimeInterval(60)),
            ReviewExport.Entry(ficheID: "fr.eminent", headword: "éminent", reason: .confirmed, comment: nil, createdAt: early),
        ]
        let lines = ReviewExport.csv(entries).split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines[0] == "fiche_id,mot,verdict,commentaire,date")
        #expect(lines[1] == "fr.eminent,éminent,confirmed,,2027-01-15T08:00:00Z")
        #expect(lines[2] == "fr.pallier,pallier,definition,\"Il manque \"\"un\"\" sens,")
        #expect(lines[3] == "voir Littré\",2027-01-15T08:01:00Z")
    }
}
