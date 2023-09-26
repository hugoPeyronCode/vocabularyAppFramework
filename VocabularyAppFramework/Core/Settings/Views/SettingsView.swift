//
//  SettingsView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 20/09/2023.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var isShowingPremiumView : Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Title
                
                BuyPremiumButton
                    .padding()

                List {

                    SettingsSection

                    YourWordsSection

                }
            }
            .navigationBarItems(leading: CancelButton)
            .navigationDestination(isPresented: $isShowingPremiumView) {
                PremiumView()
            }
        }
    }
    
    var CancelButton : some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Done")
                .foregroundColor(.primary)
                .font(.subheadline)
        }
    }

    var Title : some View {
        HStack() {
            Text("Vocabulary")
                .font(.title)
                .bold()
            Spacer()
        }
        .padding(.leading)
    }

    var BuyPremiumButton : some View {
        
        CustomButtonMarked(text: "Try Vocabulary Free", action: { isShowingPremiumView.toggle()})
    }

    var SettingsSection : some View {
        Section("Settings") {
            NavigationLink(destination: GeneralView()) {
                HStack(spacing: 20) {
                    Image(systemName: "gearshape.fill")
                    Text("General")
                }
            }
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "bell.fill")
                    Text("Reminders")
                }
            }

            NavigationLink(destination: ChangeIconView()) {
                HStack(spacing: 20) {
                    Image(systemName: "square.fill")
                    Text("Change Icon")
                }
            }

            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "rectangle.grid.2x2.fill")
                    Text("Lock Screen Widgets")
                }
            }
        }
    }

    var YourWordsSection : some View {
        Section("Your Words") {
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "bookmark.fill")
                    Text("Collections")
                }
            }
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "bell.fill")
                    Text("Add Your Own")
                }
            }

            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            }

            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "clock.fill")
                    Text("Past Words")
                }
            }

            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
