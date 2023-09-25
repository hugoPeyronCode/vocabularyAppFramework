//
//  ManageSubscriptionView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 20/09/2023.
//

import SwiftUI

struct ManageSubscriptionView: View {
    var body: some View {
        
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 30){
                HeaderText
                
                StartedExpired
            }
            
            
            Spacer()
            
            CustomButtonMarked(text: "Go Premium", action: {})
                .padding()
        }
        .padding()
        .navigationTitle("Manage Subscription")
        
    }
    
    
    var HeaderText : some View {
        
        VStack(alignment: .leading, spacing: 30) {
            Text("You are not subscribed to:")
                .font(.callout)

            HStack(spacing: 0) {
                Image(systemName: "crown")
                    .font(.title)
                    .offset(x: -10)
                Text("Vocabulary yearly Premium")
                    .bold()
            }
            .font(.title3)
        }
    }
    
    
    var StartedExpired : some View {
        VStack(alignment: .leading, spacing: 30){
            HStack(spacing: 30){
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.cyan)
                Text("Started:")
                Text("06/05/2023")
            }
            
            HStack(spacing: 30){
                Image(systemName: "x.circle.fill")
                    .foregroundColor(.pink)
                Text("Expired:")
                Text("09/05/2023")
            }
        }
    }
}

struct ManageSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        ManageSubscriptionView()
    }
}
