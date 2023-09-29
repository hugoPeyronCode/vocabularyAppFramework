//
//  ThemesView.swift
//  VocabularyAppFramework
//

import SwiftUI

struct ThemesView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var themesManager: ThemesManager

    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(ThemesCategories.allCases, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 1) {
                        
                        HStack {
                            Text("\(category.displayName)")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ColoredThemes(for: category)
                    }
                }
                .navigationTitle("Categories")
                .navigationBarItems(
                    leading: CancelButton,
                    trailing: UnlockAllButton
                )
            }
            .background(Color.main.opacity(0.1))
        }
    }
    
    var UnlockAllButton : some View {
        NavigationLink {
            PremiumView()
        } label: {
            Text("Unlock All").font(.subheadline).foregroundColor(.primary)
        }
    }
    
    var CancelButton : some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Cancel")
                .foregroundColor(.primary)
                .font(.subheadline)
        }
    }
    
    // This view represents one horizontal scroll view of theme buttons for a category
    func ColoredThemes(for category: ThemesCategories) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(themesManager.themesDict[category] ?? [], id: \.self) { theme in
                    ThemeButton(theme: theme) { selectedTheme in
                        themesManager.currentTheme = selectedTheme
                        presentationMode.wrappedValue.dismiss()
                    }.environmentObject(themesManager)
                }
            }
            .padding()
        }
    }
}

struct ThemesView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesView().environmentObject(ThemesManager())
    }
}

