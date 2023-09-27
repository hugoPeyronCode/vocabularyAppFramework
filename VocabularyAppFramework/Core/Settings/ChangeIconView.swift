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
    
    let customIcons: [String] = ["AppIcon1", "AppIcon2", "AppIcon3", "AppIcon4", "AppIcon5", "AppIcon6", "AppIcon7", "AppIcon8", "AppIcon9","AppIcon10","AppIcon11","AppIcon12","AppIcon13","AppIcon14","AppIcon15", "AppIcon16","AppIcon17", "AppIcon18", "AppIcon19", "AppIcon20", "AppIcon21", "AppIcon22","AppIcon23", "AppIcon24", "AppIcon25" ]
    
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
                                .shadow(color: .main, radius: icon == activeIcon ? 3 : 0)
                                .shadow(color: .main, radius: icon == activeIcon ? 3 : 0)
                                .shadow(color: .main, radius: icon == activeIcon ? 3 : 0)
                                .shadow(color: .main, radius: icon == activeIcon ? 3 : 0)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select an Icon")
        }
    }
}

struct ChangeIconView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeIconView()
    }
}
