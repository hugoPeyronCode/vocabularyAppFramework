//
//  CategoriesView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct CategoriesView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject private var storeKitManager : StoreKitManager
    
    @State var vm : HomeViewModel

    @Binding var isShowingCategoriesView: Bool
    
    @State private var navigateToMixView: Bool = false
    @State private var navigateToPremiumView : Bool = false

    let topCategories = ["society", "human body", "food", "people", "travel", "technology", "science", "literature", "history", "geography", "art", "business", "emotion", "nature", "health"]
    let subCategories = ["animals", "architecture", "colors", "crime", "currency", "fashion", "law", "mathematics", "plants", "politic", "religion", "slang", "music", "sounds", "sports", "time", "tools", "war", "other"]
    
    let columns: [GridItem] = [
        GridItem(.flexible()),  // Width of button + padding
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    
                    MakeYourOwnMixButton
                    
                    LazyVGrid(columns: columns, spacing: 0) {
                        CategoryButton(text: "All", icon: vm.selectedCategories.contains("all") ? "checkmark.circle" : "", hasUnlockPremium: true) {
                            HapticManager.shared.generateFeedback(for: .successStrong)
                            vm.selectedCategories.removeAll()
                            vm.selectedCategory = "all" // Set to "All" when the "All" button is clicked
                            isShowingCategoriesView = false
                        }
                        CategoryButton(text: "My Favorites", icon: vm.selectedCategories.contains("My Favorite") ? "checkmark.circle" : "", hasUnlockPremium: storeKitManager.hasUnlockedPremium) {
                            
                            if storeKitManager.hasUnlockedPremium {
                                HapticManager.shared.generateFeedback(for: .successStrong)
                                vm.selectedCategories.removeAll()
                                vm.selectedCategory = "My Favorites"
                                isShowingCategoriesView = false
                            } else {
                                HapticManager.shared.generateFeedback(for: .errorStrong)
                                navigateToPremiumView.toggle()
                            }
                        }
                      }
                    
                    Text("Main topics")
                        .bold()
                        .font(.title3)
                        .padding(.leading)
                    
                    GridMainCategories
                    
                    Text("Subtopics")
                        .bold()
                        .font(.title3)
                        .padding(.leading)
                    
                    GridSubCategories
                    
                    Spacer()
                }
                .navigationTitle("Categories")
                .navigationBarItems(
                    leading: CancelButton,
                    trailing: UnlockAllButton
            )
            }
            .background(Color.main.opacity(0.1))
            .navigationDestination(isPresented: $navigateToMixView) {
                MakeYourOwnMixView(vm: vm, topCategories: topCategories, subCategories: subCategories)
            }
            .navigationDestination(isPresented: $navigateToPremiumView) {
                PremiumView()
            }
        }
    }
    
    var UnlockAllButton : some View {
        Button {
            HapticManager.shared.generateFeedback(for: .successLight)
            navigateToPremiumView.toggle()
        } label: {
            Text(storeKitManager.hasUnlockedPremium ? "" : "Unlock All")
                .font(.subheadline).foregroundColor(.primary)
        }
    }
    
    var CancelButton : some View {
        Button {
            HapticManager.shared.generateFeedback(for: .successLight)
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Cancel")
                .foregroundColor(.primary)
                .font(.subheadline)
        }
    }
    
    var MakeYourOwnMixButton: some View {
        CustomButtonMarked(text: "Make your own mix", isActive: true) {
            if storeKitManager.hasUnlockedPremium {
                HapticManager.shared.generateFeedback(for: .successStrong)
                navigateToMixView.toggle()
            } else {
                HapticManager.shared.generateFeedback(for: .errorStrong)
                navigateToPremiumView.toggle()
            }
        }
        .padding()
    }
    
    var GridMainCategories : some View {
      LazyVGrid(columns: columns, spacing: 0) {
            ForEach(topCategories, id: \.self) { category in
                CategoryButton(text: category.capitalized, icon: vm.selectedCategories.contains(category) ? "checkmark.circle" : "", hasUnlockPremium: storeKitManager.hasUnlockedPremium) {
                    if storeKitManager.hasUnlockedPremium {
                        HapticManager.shared.generateFeedback(for: .successStrong)
                        vm.selectedCategories.removeAll()
                        vm.selectedCategory = category
                        isShowingCategoriesView = false
                    } else {
                        HapticManager.shared.generateFeedback(for: .errorStrong)
                        navigateToPremiumView.toggle()
                    }
                }
            }
        }
    }
    
    var GridSubCategories : some View {
      LazyVGrid(columns: columns, spacing: 0) {
          ForEach(subCategories, id: \.self) { category in
              CategoryButton(text: category.capitalized, icon: vm.selectedCategories.contains(category) ? "checkmark.circle" : "", hasUnlockPremium: storeKitManager.hasUnlockedPremium) {
                  if storeKitManager.hasUnlockedPremium {
                      HapticManager.shared.generateFeedback(for: .successStrong)
                      vm.selectedCategories.removeAll()
                      vm.selectedCategory = category
                      isShowingCategoriesView = false
                  } else {
                      HapticManager.shared.generateFeedback(for: .errorStrong)
                      navigateToPremiumView.toggle()
                  }
              }
            }
        }
    }
}

struct CategoriesView_Previews: PreviewProvider {
    
    static let allWords = WordManager.shared.allWords
    
    static var previews: some View {
        CategoriesView(vm: HomeViewModel(allWords: WordManager.shared.allWords, wordsByCategory: WordManager.shared.wordsByCategory), isShowingCategoriesView: .constant(true))
            .environmentObject(StoreKitManager())
    }
}
