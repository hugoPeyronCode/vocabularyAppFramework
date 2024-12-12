//
//  CustomButton.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct HomeSquareButton: View {
  @EnvironmentObject var themesManager : ThemesManager
  let text : String
  let image : String
  @State private var isTapped: Bool = false
  let action : () -> Void

  var body: some View {
    Button {
      isTapped.toggle()
      action()
    } label: {
      HStack(spacing: 3) {
        Image(systemName: image)
          .fontWeight(.thin)
        Text(text)
          .fontWeight(.light)
          .font(.caption)
      }
      .sensoryFeedback(.impact, trigger: isTapped)
      .frame(height: 25)
      .padding()
      .foregroundColor(themesManager.currentTheme.fontColor)
      .background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .shadow(color: themesManager.currentTheme.fontColor.opacity(0.3), radius: 1)
    }
  }
}

struct CustomButton_Previews: PreviewProvider {
  static var previews: some View {
    HomeSquareButton(text: "Category", image: "crown", action: {})
      .environmentObject(ThemesManager())
  }
}
