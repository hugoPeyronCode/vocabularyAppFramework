//
//  ThemesView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//
import SwiftUI

struct ThemesView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(0 ..< 5) { item in
                    ThemeCategoryScrollView
                }
            }
            .background(Color.main.opacity(0.1))
            .navigationTitle("Themes")
            .navigationBarItems(
                leading: CancelButton,
                trailing: UnlockAllButton
            )
        }
        
    }
    
    var UnlockAllButton : some View {
        NavigationLink {
            PremiumView()
        } label: {
            Text("Unlock All").font(.subheadline).foregroundColor(.primary)
        }
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
    var ThemeCategoryScrollView: some View {
        
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text("Category 2")
                    .font(.headline)
                Spacer()
                
                Text("View All")
                    .font(.caption)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0 ..< 5) { item in
                        ThemeButton(mainImage: "All", action: {})
                    }
                    ThemeButton(mainImage: "All",action: {})
                }
                .padding()
            }
        }
    }
}

struct ThemesView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesView()
    }
}
