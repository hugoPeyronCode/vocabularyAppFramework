//
//  OnboardingView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 30/10/2023.
//

import SwiftUI

struct OnboardingView: View {
  
  @StateObject var vm = TabViewModel()
  @EnvironmentObject var themesManager: ThemesManager
  
  var isMain : Bool { themesManager.currentTheme.backgroundImage == "Main" }
  
  
  var body: some View {
    TabView(selection: $vm.selectedTab) {
      IntroView(vm: vm)
        .tag(0)
      
      SurveyView(vm: vm)
        .tag(1)
      
      UserLevelView(vm: vm)
        .tag(2)
      
      AskForRatingView(vm: vm)
        .tag(3)
      
      NotificationsSettingsView(vm: vm)
        .tag(4)
        .onAppear {
          UIScrollView.appearance().isScrollEnabled = true
        }
      PremiumView()
        .tag(5)
    }
    .background(
      ZStack{
        Image(themesManager.currentTheme.backgroundImage).opacity(isMain ? 0.2 : 1)
        if themesManager.currentTheme.needContrast == true {
          Color(.black).opacity(0.2)
        }
      }
    )
    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    .onAppear {
      UIScrollView.appearance().isScrollEnabled = false
    }
  }
}

extension OnboardingView {
  class TabViewModel: ObservableObject {
    @Published var selectedTab = 0
    
    func moveToNextPage() {
      DispatchQueue.main.async {
        withAnimation {
          self.selectedTab += 1
        }
      }
    }
  }
}


#Preview {
  OnboardingView()
    .environmentObject(ThemesManager())
    .environmentObject(StoreKitManager())
}
