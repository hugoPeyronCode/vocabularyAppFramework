import SagaceCore
import SagaceUI
import SwiftUI

struct AppLanguagePicker: View {
    let dependencies: AppDependencies
    @State private var failed = false

    var body: some View {
        Text("Langue de l’app", tableName: "LanguageSettings")
            .textStyle(.metricLabel).textCase(.uppercase).padding(.top, 10)
        ForEach(AppLanguagePreference.allCases, id: \.self) { preference in
            Button {
                Task { failed = !(await dependencies.setLanguage(preference)) }
            } label: {
                HStack {
                    label(preference).fontStyle(.rowTitle)
                    Spacer()
                    if dependencies.languagePreference == preference {
                        Image(systemName: "checkmark").accessibilityHidden(true)
                    }
                }
                .foregroundStyle(.vTextPrimary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
            }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityIdentifier("appLanguage.\(preference.rawValue)")
            .accessibilityAddTraits(dependencies.languagePreference == preference ? .isSelected : [])
            .disabled(dependencies.isChangingLanguage)
        }
        Text("Automatique suit la langue de l’appareil. Ce choix change l’interface et les mots proposés. Le changement vous ramène aux mots ; votre progression est conservée.", tableName: "LanguageSettings")
            .textStyle(.meta)
        if dependencies.isChangingLanguage { ProgressView() }
        if failed {
            Text("La langue n’a pas pu être changée. Réessayez.", tableName: "LanguageSettings")
                .textStyle(.body)
                .accessibilityIdentifier("appLanguage.error")
        }
    }

    private func label(_ preference: AppLanguagePreference) -> Text {
        switch preference {
        case .automatic: Text("Automatique", tableName: "LanguageSettings")
        case .fr: Text(verbatim: "Français")
        case .en: Text(verbatim: "English")
        }
    }
}
