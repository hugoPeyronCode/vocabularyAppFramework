//
//  QuizSettingsView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 02/11/2023.
//

import SwiftUI

struct QuizSettingsView: View {
    @Binding var quizApparitionValue: Int
    @State private var sliderValue: Double
    @Environment(\.dismiss) var dismiss
    
    init(quizApparitionValue: Binding<Int>) {
        self._quizApparitionValue = quizApparitionValue
        self._sliderValue = State(initialValue: Double(quizApparitionValue.wrappedValue))
    }

    var body: some View {
        VStack {
            Spacer()
            BackgroundImageView(imageName: "pipes")
                .scaleEffect(0.7)
            Spacer()
            
            Text("At what frequency do you want to see a quiz?")
                .bold()
                .multilineTextAlignment(.center)
                .fontDesign(.serif)
                .font(.title)
                .padding()
            // This Text view will now update as the sliderValue changes
            Text(sliderValue == 1 ? "Always" :  sliderValue == 12  ? "Never": "One quiz every \(Int(sliderValue - 1)) words")
                .font(.title3)
                .fontDesign(.rounded)
                .padding(.top)
            
            Slider(value: $sliderValue, in: 1...12, step: 1)
                .tint(.main)
                .onChange(of: sliderValue) { _, newValue in
                    // This will trigger every time the sliderValue changes
                    quizApparitionValue = Int(newValue)
                    saveQuizApparitionValue()
                }
                .padding(.horizontal)
            
            Spacer()
        
            
            MoveToNextPageButton(content: "Save", icon: "", defaultColor: .main, fontString: ".rounded", isActive: .constant(true)) {
                saveQuizApparitionValue()
                dismiss()
            }
            .padding(.bottom, 50)
            
        }
    }
    
    private func saveQuizApparitionValue() {
        UserDefaults.standard.set(quizApparitionValue, forKey: "quizApparitionValue")
    }
}

#Preview {
    QuizSettingsView(quizApparitionValue: .constant(10))
}
