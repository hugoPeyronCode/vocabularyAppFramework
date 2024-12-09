//
//  TypingAnimation.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 09/12/2024.
//

import SwiftUI
import Combine

struct TypingAnimation: ViewModifier {
  let text: String
  @Binding var isAnimating: Bool
  let typingInterval: Double

  @State private var displayedText: String = ""
  @State private var cancellable: AnyCancellable?

  func body(content: Content) -> some View {
    Text(displayedText)
      .onChange(of: isAnimating) { _, startAnimation in
        print("Animation triggered: \(startAnimation)")
        if startAnimation {
          startTypingAnimation()
        } else {
          resetAnimation()
        }
      }
      .onAppear {
        print("Initial text: \(text)")
      }
  }

  private func startTypingAnimation() {
    print("Starting animation")
    resetAnimation()

    let characters = Array(text)
    var currentIndex = 0

    cancellable = Timer.publish(every: typingInterval, on: .main, in: .common)
      .autoconnect()
      .sink { _ in
        guard currentIndex < characters.count else {
          print("Animation completed")
          cancellable?.cancel()
          return
        }

        displayedText += String(characters[currentIndex])
        print("Current text: \(displayedText)")
        currentIndex += 1
      }
  }

  private func resetAnimation() {
    cancellable?.cancel()
    cancellable = nil
    displayedText = ""
  }
}

extension View {
  func typingAnimation(text: String, isAnimating: Binding<Bool>, typingInterval: Double = 0.05) -> some View {
    modifier(TypingAnimation(text: text, isAnimating: isAnimating, typingInterval: typingInterval))
  }
}

struct TypingAnimationTestView: View {
  @State private var isAnimating = false
  @State private var selectedText = "Hello World!"

  let testMessages = [
    "Hello World!",
    "This is a longer message to test the animation with multiple words.",
    "1234567890",
    "Short",
    "This\nis\na\nmultiline\ntest"
  ]

  var body: some View {
    VStack(spacing: 20) {
      // Debug information
      Text("Animation State: \(isAnimating ? "Active" : "Inactive")")
        .font(.caption)
        .foregroundStyle(.gray)

      // Animation display area
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray.opacity(0.1))
        .frame(height: 200)
        .overlay(
          Text("")
            .typingAnimation(text: selectedText, isAnimating: $isAnimating)
            .foregroundColor(.primary)
            .font(.title2)
            .padding()
        )

      // Controls
      VStack(spacing: 16) {
        Button(action: {
          print("Start button tapped")
          isAnimating = false
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("Setting isAnimating to true")
            isAnimating = true
          }
        }) {
          Text("Start Animation")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }

        Button(action: {
          print("Reset button tapped")
          isAnimating = false
        }) {
          Text("Reset")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }

        Picker("Select Test Text", selection: $selectedText) {
          ForEach(testMessages, id: \.self) { message in
            Text(message)
              .tag(message)
          }
        }
        .pickerStyle(.menu)
      }
      .padding()
    }
    .padding()
  }
}

#Preview {
  TypingAnimationTestView()
}
