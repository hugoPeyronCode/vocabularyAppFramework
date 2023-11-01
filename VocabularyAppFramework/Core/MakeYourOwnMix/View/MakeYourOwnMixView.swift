//
//  MakeYourOwnMixView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 23/09/2023.
//

import SwiftUI

struct MakeYourOwnMixView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @ObservedObject var vm : HomeViewModel
    
    @State var isSelected : Bool = false
    
    let topCategories : [String]
    let subCategories : [String]
    
    @State var selectedCategories: [String]? = []
    
    
    var body: some View {
        NavigationStack {
                VStack{
                    CustomButtonMarked(text: "Save Selection", isActive: true, action: {
                        presentationMode.wrappedValue.dismiss()
                        presentationMode.wrappedValue.dismiss()
                        vm.selectedCategories = selectedCategories ?? ["Error"]
                        print(selectedCategories ?? [""])
                        print("vm \(vm.selectedCategories)")
                    })
                        .padding()
                    List {
                        Section {
                            ButtonList(content: "All", isSelected: selectedCategories?.contains("all") ?? false) {
                                if selectedCategories?.contains("all") == true {
                                    selectedCategories?.removeAll() // Deselect all categories
                                } else {
                                    selectedCategories = ["all", "My Favorites"] + topCategories + subCategories
                                }
                            }
                            ButtonList(content: "My Favorites", isSelected: selectedCategories?.contains("My Favorites") ?? false) {
                                if let index = selectedCategories?.firstIndex(of: "My Favorites") {
                                    selectedCategories?.remove(at: index)
                                } else {
                                    selectedCategories?.append("My Favorites")
                                }
                            }
                        }

                        Section("By Top Categories") {
                            ForEach(topCategories, id: \.self) { category in
                                ButtonList(content: category.capitalized, isSelected: selectedCategories?.contains(category) ?? false) {
                                    if let index = selectedCategories?.firstIndex(of: category) {
                                        selectedCategories?.remove(at: index)
                                    } else {
                                        selectedCategories?.append(category)
                                    }
                                }
                            }
                        }
                        Section("By Sub Categories") {
                            ForEach(subCategories, id: \.self) { category in
                                ButtonList(content: category.capitalized, isSelected: selectedCategories?.contains(category) ?? false) {
                                    if let index = selectedCategories?.firstIndex(of: category) {
                                        selectedCategories?.remove(at: index)
                                    } else {
                                        selectedCategories?.append(category)
                                    }
                                }
                            }
                        }
                }
                .navigationTitle("Make Your Own Mix")
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(leading: CancelButton)
            }
            .background(Color.main.opacity(0.1))
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
}

struct MakeYourOwnMixView_Previews: PreviewProvider {
    
    static let topCategories = ["society", "human body", "food", "people", "travel", "technology", "science", "literature", "history", "geography", "art", "business", "emotion", "nature", "health"]
    static let subCategories = ["animals", "architecture", "colors", "crime", "currency", "fashion", "law", "mathematics", "plants", "politic", "religion", "slang", "music", "sounds", "sports", "time", "tools", "war", "other"]
    
    static var previews: some View {
        MakeYourOwnMixView(vm: HomeViewModel(allWords: WordManager.shared.allWords, wordsByCategory: WordManager.shared.wordsByCategory), topCategories: topCategories, subCategories: subCategories, selectedCategories: [])
    }
}

struct ButtonList : View {
    
    let content : String
    let isSelected : Bool
    let action : () -> Void
    
    var body: some View{
        Button {
            action()
        } label: {
            HStack {
                Text(content)
                    .foregroundColor(isSelected ? .primary : .gray)
                Spacer()
                Image(systemName: isSelected ?  "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .main : .primary)
                    .fontWeight(.light)
            }
        }
    }
}
