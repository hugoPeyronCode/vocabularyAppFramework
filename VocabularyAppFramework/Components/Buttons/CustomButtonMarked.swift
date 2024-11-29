//
//  CustomButtonMarked.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI

struct CustomButtonMarked: View {

  let text : String
  @State var isActive : Bool
  let action : () -> Void

  var body: some View {

    Button {
      action()
      HapticManager.shared.generateFeedback(for: .successLight)
    } label: {
      Text(text)
        .fontDesign(.rounded)
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .background(
          ZStack{
            Capsule()
              .offset(y: 5)
              .foregroundColor(.primary)
              .opacity(isActive ? 1 : 0.2)
            Capsule()
              .foregroundColor(.main)
              .opacity(isActive ? 1 : 0.8)
          }
        )
    }
    .disabled(!isActive)
  }
}

struct CustomButtonMarked_Previews: PreviewProvider {
  static var previews: some View {
    CustomButtonMarked(text: "Make your own mix", isActive: true, action: {})
  }
}
