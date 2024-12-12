//
//  ContentView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct HomeView: View {

  @State var vm: HomeViewModel

  @EnvironmentObject var themesManager: ThemesManager
  @EnvironmentObject private var storeKitManager : StoreKitManager

  var isMain : Bool { themesManager.currentTheme.backgroundImage == "Main" }

  init(allWords: Set<Word>, wordsByCategories: [String: Set<Word>]) {
    _vm = State(wrappedValue: HomeViewModel(allWords: allWords, wordsByCategory: wordsByCategories))
  }

  var body: some View {

    ZStack {

      ScrollingContent

      QuizzSettingsButton

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
    .sheet(isPresented: $vm.isShowingQuizzSettingsView) { QuizSettingsView(quizApparitionValue : $vm.quizzApparitionValue)
    }
    .sheet(isPresented: $vm.isShowingPremiumView) { PremiumView() }
    .sheet(isPresented: $vm.isShowingCategoriesView) {
      CategoriesView(vm: vm, isShowingCategoriesView: $vm.isShowingCategoriesView)
        .environmentObject(storeKitManager)
    }
    .sheet(isPresented: $vm.isShowingThemesView) { ThemesView().environmentObject(themesManager) }
    .sheet(isPresented: $vm.isShowingSettingsView) { SettingsView() }
  }

  var ScrollingContent: some View {
    GeometryReader { screen in
      TabView(selection: $vm.currentPage) {
        ForEach(Array(vm.filteredWords.enumerated()), id: \.element) { index, word in
          Group {
            switch vm.getViewType(for: index) {
            case .wordDisplay:
              WordView(
                viewModel: vm, word: word,
                fontColor: themesManager.currentTheme.fontColor,
                fontString: themesManager.currentTheme.font
              )

            case .wordWriting:
              WordWritingView(
                word: word,
                fontColor: themesManager.currentTheme.fontColor,
                fontString: themesManager.currentTheme.font
              )

            case .fillInBlanks:
              FillInBlanksView(
                word: word,
                fontColor: themesManager.currentTheme.fontColor,
                fontString: themesManager.currentTheme.font
              )

            case .anagrams:
              AnagramView(
                word: word,
                fontColor: themesManager.currentTheme.fontColor,
                fontString: themesManager.currentTheme.font
              )
            }
          }
          .frame(width: screen.size.width, height: screen.size.height)
          .rotationEffect(Angle(degrees: -90))
          .sensoryFeedback(.impact, trigger: index)
          .tag(index)
        }
      }
      .frame(width: screen.size.height, height: screen.size.width)
      .rotationEffect(.degrees(90), anchor: .topLeading)
      .offset(x: screen.size.width)
      .tabViewStyle(.page(indexDisplayMode: .never))
    }
  }

  var QuizzSettingsButton : some View {
    VStack {
      HStack {
        HomeSquareButton(text: "", image: "slider.horizontal.3", action: {
          vm.isShowingQuizzSettingsView.toggle()
        })
        Spacer()
      }
      Spacer()
    }
    .padding()
  }

  var PremiumButton : some View {
    VStack {
      HStack {
        Spacer()
        HomeSquareButton(text: "", image: "crown", action: {
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
        HomeSquareButton(text: vm.selectedCategories.isEmpty ? vm.selectedCategory  : "Mix" , image: "square.grid.2x2", action: {
          vm.isShowingCategoriesView.toggle()
        })

        Spacer()
        HomeSquareButton(text: "", image: "paintbrush", action: {
          vm.isShowingThemesView.toggle()
        })
        HomeSquareButton(text: "", image: "person", action: {
          vm.isShowingSettingsView.toggle()
        })

      }
      .padding()
    }
  }
}

struct Home_Previews: PreviewProvider {
  static var previews: some View {
    HomeView(allWords: WordManager.shared.allWords, wordsByCategories: WordManager.shared.wordsByCategory)
      .environmentObject(ThemesManager())
      .environmentObject(StoreKitManager())
  }
}
