//
//  ContentView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct Home: View {
        
    @StateObject var vm: HomeViewModel
    
    @EnvironmentObject var themesManager: ThemesManager
    @EnvironmentObject private var storeKitManager : StoreKitManager
    
    var isMain : Bool { themesManager.currentTheme.backgroundImage == "Main" }
    
    init(allWords: Set<Word>, wordsByCategories: [String: Set<Word>]) {
        _vm = StateObject(wrappedValue: HomeViewModel(allWords: allWords, wordsByCategory: wordsByCategories))
    }
    var body: some View {
        
        ZStack {
            
            ScrollingWords
            
            if !storeKitManager.hasUnlockedPremium { PremiumButton }
            
            BottomBar
            
        }
        .background(
            ZStack{
                Image(themesManager.currentTheme.backgroundImage).opacity(isMain ? 0.2 : 1)
                if themesManager.currentTheme.needContrast == true {
                    Color(.black).opacity(0.2)
                }
            }
        )
        .sheet(isPresented: $vm.isShowingPremiumView) { PremiumView() }
        .sheet(isPresented: $vm.isShowingCategoriesView) {
            CategoriesView(vm: vm, isShowingCategoriesView: $vm.isShowingCategoriesView)
                .environmentObject(storeKitManager)
        }
        .sheet(isPresented: $vm.isShowingThemesView) { ThemesView().environmentObject(themesManager) }
        .sheet(isPresented: $vm.isShowingSettingsView) { SettingsView() }
    }
    
    var ScrollingWords: some View {
        GeometryReader { screen in
            let wordsArray = Array(vm.filteredWords)
            TabView(selection: $vm.currentPage) {
                ForEach(0..<wordsArray.count, id: \.self) { index in
                    LazyVStack {
                        if index % 5 == 0 && index != 0 {
                            QCMView(word: wordsArray[index], fontColor: themesManager.currentTheme.fontColor, fontString: themesManager.currentTheme.font)
                        } else {
                            WordView(viewModel: vm, word: wordsArray[index], fontColor: themesManager.currentTheme.fontColor, fontString: themesManager.currentTheme.font)
                        }
                    }
                    .onAppear{
                        HapticManager.shared.generateFeedback(for: .successLight)
                    }
                    .frame(width: screen.size.width, height: screen.size.height)
                    .rotationEffect(Angle(degrees: -90))
                    .tag(index)
                }
            }
            .frame(width: screen.size.height, height: screen.size.width)
            .rotationEffect(.degrees(90), anchor: .topLeading)
            .offset(x: screen.size.width) // Offset back into screens bounds
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
    }
    
    var PremiumButton : some View {
        VStack {
            HStack {
                Spacer()
                CustomButton(text: "", image: "crown", action: {
                    HapticManager.shared.generateFeedback(for: .successLight)
                    vm.isShowingPremiumView.toggle()
                })
            }
            Spacer()
        }
        .padding()
    }
    
    var BottomBar : some View {
        VStack {
            
            Spacer()
            
            HStack {
                CustomButton(text: vm.selectedCategories.isEmpty ? vm.selectedCategory  : "Mix" , image: "square.grid.2x2", action: {
                    HapticManager.shared.generateFeedback(for: .successLight)
                    vm.isShowingCategoriesView.toggle()
                })
                
                Spacer()
                CustomButton(text: "", image: "paintbrush", action: {
                    HapticManager.shared.generateFeedback(for: .successLight)
                    vm.isShowingThemesView.toggle()
                })
                CustomButton(text: "", image: "person", action: {
                    HapticManager.shared.generateFeedback(for: .successLight)
                    vm.isShowingSettingsView.toggle()
                })
                
            }
            .padding()
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home(allWords: WordManager.shared.allWords, wordsByCategories: WordManager.shared.wordsByCategory)
            .environmentObject(ThemesManager())
            .environmentObject(StoreKitManager())
    }
}
