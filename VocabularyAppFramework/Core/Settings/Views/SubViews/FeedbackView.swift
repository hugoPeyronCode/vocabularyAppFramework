//
//  FeedbackView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 02/10/2023.
//

import SwiftUI
struct FeedbackView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("We Value Your Feedback!")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                Text("Dear Word app user,")
                    .font(.headline)
                    .padding(.vertical, 5)
                
                Text("We hope you’re enjoying using the Word app! Your experience is important to us, and we'd love to hear your thoughts and feedback. If you have any suggestions, issues, or anything you’d like to share about the app, please don’t hesitate to let us know.")
                    .padding(.vertical, 5)
                
                Text("Kindly send us your complete feedback via email:")
                    .padding(.vertical, 5)
                
                Text("hugopeyron@gmail.com")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.vertical, 5)
                
                Text("Your input will help us improve and provide a better experience for all users. Thank you for taking the time to share your feedback!")
                    .padding(.vertical, 5)
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    FeedbackView()
}
