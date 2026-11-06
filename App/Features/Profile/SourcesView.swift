import Foundation
import Observation
import SagaceCore
import SagaceUI
import SwiftUI

/// Sources et licences : les sources réellement citées par les fiches du pack, les phrases d'auteur, les licences.
@MainActor @Observable
final class SourcesViewModel {
    struct Source: Identifiable, Equatable {
        let name: String
        let url: URL?
        let ficheCount: Int
        var id: String { name }
    }

    let sources: [Source]
    let ficheCount: Int
    let quoteCount: Int

    init(content: ContentRepository) {
        var counts: [String: (url: URL?, count: Int)] = [:]
        for fiche in content.fiches {
            for source in Set(fiche.sources) {
                // Lien vers le site de la source, pas vers la page d'une fiche.
                let site = URL(string: source.url).flatMap { url in url.host().map { URL(string: "\(url.scheme ?? "https")://\($0)") } } ?? nil
                counts[source.name, default: (site, 0)].count += 1
            }
        }
        sources = counts.map { Source(name: $0.key, url: $0.value.url, ficheCount: $0.value.count) }
            .sorted { ($1.ficheCount, $0.name) < ($0.ficheCount, $1.name) }
        ficheCount = content.fiches.count
        quoteCount = content.fiches.filter { $0.authorQuote != nil }.count
    }
}

struct SourcesView: View {
    @State var viewModel: SourcesViewModel

    private let licence = URL(string: "https://creativecommons.org/licenses/by-sa/4.0/deed.fr")

    var body: some View {
        SheetPage("Sources et licences") {
            ScrollView {
                VStack(alignment: .leading, spacing: SagaceMetrics.rowSpacing) {
                    sectionTitle("Sources des fiches")
                    Text("\(viewModel.ficheCount) fiches, chacune avec ses sources, visibles en bas de la fiche détaillée.").textStyle(.body)
                    ForEach(viewModel.sources) { source in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: source.name).fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
                                Text("Citée par \(source.ficheCount) fiches").textStyle(.meta)
                            }
                            Spacer()
                            if let url = source.url {
                                ExternalLink(url: url) {
                                    Image(systemName: "arrow.up.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.vTextSecondary)
                                }
                                .accessibilityLabel(Text("Ouvrir \(source.name)"))
                            }
                        }
                        .padding(16)
                        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                    }

                    if viewModel.quoteCount > 0 {
                        sectionTitle("Phrases d'auteur")
                        Text("\(viewModel.quoteCount) phrases d'auteurs du domaine public, citées depuis Wikisource avec l'auteur, l'œuvre et l'année.")
                            .textStyle(.body)
                    }

                    sectionTitle("Licences")
                    Text("Le Wiktionnaire et Lexique 3 sont publiés sous licence Creative Commons Attribution, partage dans les mêmes conditions (CC BY-SA 4.0). Le Littré, le Dictionnaire des synonymes de Lafaye et les textes de Wikisource sont dans le domaine public. Les fiches qui en dérivent sont publiées sous la même licence CC BY-SA 4.0.")
                        .textStyle(.body)
                    if let licence {
                        ExternalLink(url: licence) {
                            Label("Lire la licence CC BY-SA 4.0", systemImage: "doc.text").fontStyle(.body).foregroundStyle(.vBlue)
                        }
                    }

                    sectionTitle("L'app")
                    Text("Sagace n'embarque aucune bibliothèque tierce ni publicité. Icônes : SF Symbols ; voix : synthèse vocale d'iOS.")
                        .textStyle(.body)
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.bottom, 16)
            }
        }
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title).textStyle(.metricLabel).textCase(.uppercase).padding(.top, 10)
    }
}
