//
//  HapticTestView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 02/10/2023.
//

import SwiftUI

struct HapticTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Haptic Feedback Test")
                .font(.largeTitle)
                .bold()

            Button(action: {
                HapticManager.shared.generateFeedback(for: .successStrong)
            }) {
                Text("Success Strong")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: {
                HapticManager.shared.generateFeedback(for: .successLight)
            }) {
                Text("Success Light")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: {
                HapticManager.shared.generateFeedback(for: .warningStrong)
            }) {
                Text("Warning Strong")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: {
                HapticManager.shared.generateFeedback(for: .warningLight)
            }) {
                Text("Warning Light")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: {
                HapticManager.shared.generateFeedback(for: .errorStrong)
            }) {
                Text("Error Strong")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: {
                HapticManager.shared.generateFeedback(for: .errorLight)
            }) {
                Text("Error Light")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview {
    HapticTestView()
}
