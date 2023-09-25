//
//  ContentView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct Home: View {
        
    @StateObject var vm: HomeViewModel
    
    init(allWords: Set<Word>, wordsByCategories: [String: Set<Word>]) {
        _vm = StateObject(wrappedValue: HomeViewModel(allWords: allWords, wordsByCategory: wordsByCategories))
    }
    var body: some View {
        
        ZStack {
            
            ScrollingWords
            
            PremiumButton
            
            BottomBar
            
        }
        .background(Color.main.opacity(0.1))
        .sheet(isPresented: $vm.isShowingPremiumView) { PremiumView() }
        .sheet(isPresented: $vm.isShowingCategoriesView) {
            CategoriesView(vm: vm, isShowingCategoriesView: $vm.isShowingCategoriesView)
        }
        .sheet(isPresented: $vm.isShowingThemesView) { ThemesView() }
        .sheet(isPresented: $vm.isShowingSettingsView) { SettingsView() }
    }
    
    var ScrollingWords: some View {
        GeometryReader { screen in
            let wordsArray = Array(vm.filteredWords)
            TabView(selection: $vm.currentPage) {
                ForEach(0..<wordsArray.count, id: \.self) { index in
                    LazyVStack {
                        WordView(viewModel: vm, word: wordsArray[index])
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
                CustomButton(text: "", image: "crown", action: {vm.isShowingPremiumView.toggle()})
            }
            Spacer()
        }
        .padding()
    }
    
    var BottomBar : some View {
        VStack {
            
            Spacer()
            HStack {
                CustomButton(text: vm.selectedCategories.isEmpty ? vm.selectedCategory  : "Mix" , image: "square.grid.2x2", action: {vm.isShowingCategoriesView.toggle()})
                
                Spacer()
                CustomButton(text: "", image: "paintbrush", action: {vm.isShowingThemesView.toggle()})
                CustomButton(text: "", image: "person", action: {vm.isShowingSettingsView.toggle()})
                
            }
            .padding()
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home(allWords: WordManager.shared.allWords, wordsByCategories: WordManager.shared.wordsByCategory)
    }
}