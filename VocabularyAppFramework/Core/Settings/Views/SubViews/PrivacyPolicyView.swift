//
//  PrivacyPolicyView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 02/10/2023.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Privacy Policy for Word")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                SectionView(title: "1. Introduction", content: "Welcome to Hugo Peyron’s Word app. We respect the privacy of our users and are committed to protecting it through our compliance with this policy.")
                
                SectionView(title: "2. No Data Collection", content: "The Word app does not collect, use, store, or share any personal data from our users. We do not require users to provide any form of personal information to use the app.")
                
                SectionView(title: "3. Changes to This Privacy Policy", content: "We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Privacy Policy on this page. These changes are effective immediately after they are posted on this page.")
                
                SectionView(title: "4. Contact Us", content: "If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact Hugo Peyron at hugopeyron@gmail.com")
                
                SectionView(title: "5. Consent", content: "By using our app, you hereby consent to our Privacy Policy and agree to its terms.")
                
                Spacer()
            }
            .padding()
        }
    }
}

struct SectionView: View {
    var title: String
    var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .fontWeight(.semibold)
            
            Text(content)
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    PrivacyPolicyView()
}

