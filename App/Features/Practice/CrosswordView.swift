import SagaceCore
import SagaceUI
import SwiftUI

/// Mini mot croisé (Jeux) : grille, définition courante, clavier AZERTY ; à la fin, les mots et leur définition.
struct CrosswordView: View {
    @State var viewModel: CrosswordViewModel
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetContainer {
            Group {
                switch viewModel.phase {
                case .playing: playing
                case .solved: solved
                case .locked: locked
                case .empty:
                    EmptyState(systemImage: "square.grid.3x3", text: "Pas encore assez de mots pour une grille.")
                }
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
        }
        .stackedPaywall(router)
        .interactiveDismissDisabled(viewModel.isInProgress)
        .onAppear { if viewModel.engine == nil { viewModel.start() } }
    }

    // MARK: Partie

    private var playing: some View {
        VStack(spacing: 14) {
            Text("Mot croisé").textStyle(.title)
            CrosswordGridView(viewModel: viewModel)
                .modifier(Shake(animatableData: CGFloat(viewModel.shakes)))
                .animation(.easeInOut(duration: 0.4), value: viewModel.shakes)
                .frame(maxHeight: .infinity)
            HStack(spacing: 10) {
                SecondaryButton("Indice", systemImage: "lightbulb", haptic: nil) { viewModel.hint() }
                if viewModel.isFull {
                    PrimaryButton("Vérifier", haptic: nil) { viewModel.check() }
                } else if viewModel.canReveal {
                    SecondaryButton("Révéler", systemImage: "eye", haptic: nil) { viewModel.reveal() }
                }
            }
            ClueBar(viewModel: viewModel)
            CrosswordKeyboard(onLetter: viewModel.type, onNext: viewModel.nextClue, onDelete: viewModel.delete)
        }
        .padding(.bottom, 8)
    }

    // MARK: Fin

    private var solved: some View {
        ScrollView {
            VStack(spacing: 18) {
                CrosswordGridView(viewModel: viewModel)
                    .frame(height: 260)
                Text(viewModel.gaveUp ? "Grille révélée." : "Grille terminée !").textStyle(.title)
                Text("\(viewModel.foundCount) mots trouvés sur \(viewModel.words.count)").textStyle(.meta)
                VStack(spacing: SagaceMetrics.rowSpacing) {
                    ForEach(viewModel.words) { word in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: word.headword).textStyle(.rowTitle)
                                Text(verbatim: word.definition).textStyle(.body).fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            CircleButton(systemImage: "bookmark", accessibilityLabel: "À retenir", size: 40,
                                         isActive: viewModel.savedToLearn.contains(word.ficheID), haptic: nil) {
                                viewModel.saveToLearn(word.ficheID)
                            }
                        }
                        .padding(14)
                        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                    }
                }
                HStack(spacing: 12) {
                    PrimaryButton("Nouvelle grille", systemImage: "arrow.counterclockwise") { viewModel.replay() }
                    SecondaryButton("Terminer") { dismiss() }
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var locked: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 52))
                .foregroundStyle(.vTextSecondary)
                .accessibilityHidden(true)
            Text("Votre session gratuite du jour est jouée.")
                .textStyle(.definition)
                .multilineTextAlignment(.center)
            ProBanner { router.stackedPaywall = .proBanner }
            Spacer()
            SecondaryButton("Plus tard") { dismiss() }
        }
        .padding(.bottom, 12)
    }
}

/// La grille : cases ouvertes seulement, les cases noires restent vides (la forme des mots se dessine).
private struct CrosswordGridView: View {
    let viewModel: CrosswordViewModel

    var body: some View {
        GeometryReader { proxy in
            let columns = max(viewModel.columnCount, 1), rows = max(viewModel.rowCount, 1)
            let side = min((proxy.size.width - CGFloat(columns - 1) * 3) / CGFloat(columns),
                           (proxy.size.height - CGFloat(rows - 1) * 3) / CGFloat(rows), 54)
            Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                ForEach(0..<viewModel.rowCount, id: \.self) { row in
                    GridRow {
                        ForEach(viewModel.cells.filter { $0.position.row == row }) { cell in
                            CrosswordCellView(cell: cell, side: side)
                                .onTapGesture { viewModel.tap(cell.position) }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct CrosswordCellView: View {
    let cell: CrosswordViewModel.Cell
    let side: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            if cell.isOpen {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(background)
                Text(cell.letter.map(String.init) ?? "")
                    .font(.system(size: side * 0.5, weight: .bold, design: .rounded))
                    .foregroundStyle(foreground)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let number = cell.number {
                    Text(verbatim: "\(number)")
                        .font(.system(size: max(side * 0.2, 9), weight: .bold))
                        .foregroundStyle(foreground.opacity(0.7))
                        .padding(.top, 3)
                        .padding(.leading, 5)
                }
            }
        }
        .frame(width: side, height: side)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cell.isOpen ? Text(verbatim: cell.letter.map(String.init) ?? "") : Text(verbatim: ""))
        .accessibilityHidden(!cell.isOpen)
    }

    private var background: Color {
        switch cell.highlight {
        case .none: .vSurfaceRaised
        case .slot: .vSurfaceSelected
        case .current: .vBlue
        case .wrong: .vIncorrect
        case .solved: .vCorrect
        case .revealed: .vSurfaceSelected
        }
    }

    private var foreground: Color {
        switch cell.highlight {
        case .current, .wrong, .solved: .vOnAccent
        case .revealed: .vTextSecondary
        case .none, .slot: .vTextPrimary
        }
    }
}

/// Définition courante, avec la précédente et la suivante.
private struct ClueBar: View {
    let viewModel: CrosswordViewModel

    var body: some View {
        HStack(spacing: 4) {
            arrow("chevron.left", label: "Définition précédente", action: viewModel.previousClue)
            VStack(alignment: .leading, spacing: 3) {
                if let number = viewModel.clueNumber {
                    Text(viewModel.clueIsAcross ? "\(number) horizontal" : "\(number) vertical")
                        .textStyle(.metricLabel)
                        .textCase(.uppercase)
                }
                Text(verbatim: "\(viewModel.clueText) (\(viewModel.clueLength))")
                    .fontStyle(.rowTitle)
                    .foregroundStyle(.vTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            arrow("chevron.right", label: "Définition suivante", action: viewModel.nextClue)
        }
        .padding(.vertical, 10)
        .frame(minHeight: 64)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
    }

    private func arrow(_ symbol: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.vTextSecondary)
                .frame(width: 40, height: 44)
                .contentShape(.rect)
        }
        .accessibilityLabel(Text(label))
    }
}

/// Clavier AZERTY : lettres sans accents (la grille les ignore), "Suivant" et effacer.
private struct CrosswordKeyboard: View {
    let onLetter: (Character) -> Void
    let onNext: () -> Void
    let onDelete: () -> Void

    private let rows: [[Character]] = [Array("AZERTYUIOP"), Array("QSDFGHJKLM"), Array("WXCVBN")]

    var body: some View {
        VStack(spacing: 6) {
            row(rows[0])
            row(rows[1])
            HStack(spacing: 4) {
                sideKey(action: onNext, label: "Définition suivante") {
                    Image(systemName: "arrow.turn.down.right")
                }
                ForEach(rows[2], id: \.self) { letter in key(letter) }
                sideKey(action: onDelete, label: "Effacer") {
                    Image(systemName: "delete.left")
                }
            }
        }
    }

    private func row(_ letters: [Character]) -> some View {
        HStack(spacing: 4) {
            ForEach(letters, id: \.self) { letter in key(letter) }
        }
    }

    private func key(_ letter: Character) -> some View {
        Button { onLetter(letter) } label: {
            Text(String(letter))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.vTextPrimary)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(.vSurfaceRaised, in: .rect(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(Text(verbatim: String(letter)))
    }

    private func sideKey<Label: View>(action: @escaping () -> Void, label: LocalizedStringKey, @ViewBuilder content: () -> Label) -> some View {
        Button(action: action) {
            content()
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.vOnInverse)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(.vInverse, in: .rect(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        .frame(width: 62)
        .accessibilityLabel(Text(label))
    }
}

/// Secousse de la grille quand une vérification trouve des erreurs.
private struct Shake: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 6 * sin(animatableData * .pi * 4), y: 0))
    }
}
