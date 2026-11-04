import SwiftUI

/// Barre de recherche flottante en capsule ("Chercher un mot").
public struct SearchField: View {
    let prompt: Text
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    public init(_ prompt: LocalizedStringKey, text: Binding<String>, isFocused: FocusState<Bool>.Binding) {
        self.prompt = Text(prompt)
        self._text = text
        self.isFocused = isFocused
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.vTextSecondary)
            TextField(text: $text, prompt: prompt.foregroundStyle(.vTextSecondary)) { prompt }
                .fontStyle(.rowTitle)
                .foregroundStyle(.vTextPrimary)
                .focused(isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.vTextSecondary)
                }
                .accessibilityLabel(Text("Effacer", bundle: .module))
            }
        }
        .padding(.horizontal, 18)
        .frame(minHeight: SagaceMetrics.buttonHeight)
        .background(.vSurfaceRaised, in: .capsule)
        .overlay(Capsule().strokeBorder(.vSeparator))
    }
}
