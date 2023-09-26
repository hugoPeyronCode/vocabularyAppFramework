//
//  ChangeIconView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 26/09/2023.
//

import SwiftUI
import SwiftUI

struct ChangeIconView: View {
    
//    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @AppStorage("active_icon") var activeIcon: String = "AppIcon"
    
    let customIcons: [String] = ["AppIcon1", "AppIcon2", "AppIcon3", "AppIcon4", "AppIcon5", "AppIcon6"]
    
    var columns: [GridItem] = [
        GridItem(.adaptive(minimum: 100), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    
                    ForEach(customIcons, id: \.self) { icon in
                        Button(action: {
//                            presentationMode.wrappedValue.dismiss()
                            self.activeIcon = icon
                            UIApplication.shared.setAlternateIconName(icon == "AppIcon" ? nil : icon)
                        }) {
                            Image("\(icon)X")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .cornerRadius(15)
                                .shadow(radius: 3)
                                .overlay(
                                    CheckmarkView(isActive: icon == activeIcon)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select an Icon")
        }
    }
}

struct CheckmarkView: View {
    var isActive: Bool

    var body: some View {
        if isActive {
            Image(systemName: "checkmark")
                .bold()
                .foregroundColor(.white)
                .imageScale(.large)
                .transition(.scale)
        }
    }
}

struct ChangeIconView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeIconView()
    }
}
