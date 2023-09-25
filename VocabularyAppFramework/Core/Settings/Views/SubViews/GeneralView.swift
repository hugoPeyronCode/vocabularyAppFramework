//
//  GeneralView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 20/09/2023.
//

import SwiftUI

struct GeneralView: View {
    var body: some View {
        NavigationStack {
            List {
                PremiumSection
                
                MakeItYoursSection
                
                SupportUsSection
                
            }
            .navigationTitle("General")
        }
    }
    
    
    var PremiumSection : some View {
        Section("Premium"){
            NavigationLink(destination: ManageSubscriptionView()) {
                HStack(spacing: 20) {
                    Image(systemName: "crown.fill")
                    Text("Manage subsciption")
                }
            }
        }
    }
    
    
    var MakeItYoursSection : some View {
        Section("Make It Yours") {
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "waveform")
                    Text("Voice")
                }
            }
            
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "book.closed.fill")
                    Text("Content Preferences")
                }
            }
            
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "nosign")
                    Text("Forbidden Words")
                }
            }
            
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Sounds")
                }
            }
        }
    }
    
    var SupportUsSection : some View {
        Section("Support Us") {
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Vocabulary")
                }
            }
            
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "face.smiling.inverse")
                    Text("More by Hugo Peyron")
                }
            }
            
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "bubble.left.fill")
                    Text("Leave us a Review")
                }
            }
            
            NavigationLink(destination: EmptyView()) {
                HStack(spacing: 20) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Sounds")
                }
            }
        }
    }
}

struct GeneralView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralView()
    }
}
