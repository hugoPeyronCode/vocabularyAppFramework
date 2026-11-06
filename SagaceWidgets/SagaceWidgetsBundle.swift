import SwiftUI
import WidgetKit

/// Widgets de Sagace (M6, `03_ARCHITECTURE.md` section 9) : fiche du jour (accueil et écran verrouillé),
/// révision interactive, série. Tout vient du snapshot écrit par l'app dans l'App Group.
@main
struct SagaceWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FicheWidget()
        RevisionWidget()
        SerieWidget()
    }
}
