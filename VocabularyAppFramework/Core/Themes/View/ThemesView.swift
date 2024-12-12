//
//  ThemesView.swift
//  VocabularyAppFramework
//

import SwiftUI

struct ThemesView: View {

  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  @EnvironmentObject var themesManager: ThemesManager

  @EnvironmentObject var storeKitManager : StoreKitManager

  @State private var isShowingPremiumView : Bool = false

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
      .sensoryFeedback(.impact, trigger: themesManager.currentTheme)
      .sensoryFeedback(.error, trigger: !storeKitManager.hasUnlockedPremium)
      .navigationDestination(isPresented: $isShowingPremiumView, destination: {
        PremiumView()
      })
      .background(Color.main.opacity(0.1))
    }
  }

  var UnlockAllButton : some View {
    Button {
      isShowingPremiumView.toggle()
    } label: {
      Text( storeKitManager.hasUnlockedPremium ? "" : "Unlock All")
        .font(.subheadline).foregroundColor(.primary)
    }
    .sensoryFeedback(.impact, trigger: isShowingPremiumView)
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
          ThemeButton(theme: theme, hasUnlockPremium: storeKitManager.hasUnlockedPremium) { selectedTheme in
            if storeKitManager.hasUnlockedPremium {
              themesManager.currentTheme = selectedTheme
              presentationMode.wrappedValue.dismiss()
              print(selectedTheme.self)
            } else {
              isShowingPremiumView.toggle()
            }
          }
          .environmentObject(themesManager)
        }
      }
      .padding()
    }
  }
}

struct ThemesView_Previews: PreviewProvider {
  static var previews: some View {
    ThemesView()
      .environmentObject(ThemesManager())
      .environmentObject(StoreKitManager())
  }
}

