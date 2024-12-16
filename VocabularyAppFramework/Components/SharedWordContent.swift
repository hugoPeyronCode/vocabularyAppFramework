//
//  SharedWordContent.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 12/12/2024.
//

import SwiftUI

// MARK: - Individual Components

struct WordHeadwordView: View {
  let word: Word
  let fontColor: Color
  let fontString: String

  var body: some View {
    Text(word.Headword.lowercased())
      .font(.custom(fontString, size: 40))
      .minimumScaleFactor(0.7)
      .lineLimit(nil)
      .multilineTextAlignment(.center)
      .foregroundColor(fontColor)
      .shadow(radius: fontColor == .white ? 1 : 0)
      .frame(maxWidth: .infinity)
      .padding()
  }
}

struct WordDefinitionView: View {
  let word: Word
  let fontColor: Color
  let fontString: String

  var body: some View {
    Text(word.Definition)
      .font(.custom(fontString, size: 20))
//      .minimumScaleFactor(0.6)
      .lineLimit(nil)
      .multilineTextAlignment(.center)
      .foregroundColor(fontColor)
      .shadow(radius: fontColor == .white ? 1 : 0)
      .frame(maxWidth: .infinity)
      .padding()
  }
}

struct WordSentenceView: View {
  let word: Word
  let fontColor: Color
  let fontString: String

  var body: some View {
    Text("(\(word.Context_sentence))")
      .font(.custom(fontString, size: 16))
      .lineLimit(nil)
      .multilineTextAlignment(.center)
      .foregroundColor(fontColor)
      .shadow(radius: fontColor == .white ? 1 : 0)
      .frame(maxWidth: .infinity)
      .padding()
  }
}

// MARK: - Container View

struct SharedWordContent: View {
  let word: Word
  let fontColor: Color
  let fontString: String
  let headwordSize: CGFloat

  let showHeadword: Bool
  let showDefinition: Bool
  let showSentence: Bool

  let headwordOpacity: CGFloat
  let definitionOpacity: CGFloat
  let sentenceOpacity: CGFloat

  // Default initializer with all components
  init(
    word: Word,
    fontColor: Color,
    fontString: String,
    headwordSize: CGFloat = 45
  ) {
    self.init(
      word: word,
      fontColor: fontColor,
      fontString: fontString,
      headwordSize: headwordSize,
      showHeadword: true,
      showDefinition: true,
      showSentence: true,
      headwordOpacity: 1,
      definitionOpacity: 1,
      sentenceOpacity: 1
    )
  }

  // Custom initializer with control over components
  init(
    word: Word,
    fontColor: Color,
    fontString: String,
    headwordSize: CGFloat = 45,
    showHeadword: Bool = true,
    showDefinition: Bool = true,
    showSentence: Bool = true,
    headwordOpacity: CGFloat = 1,
    definitionOpacity: CGFloat = 1,
    sentenceOpacity: CGFloat = 1
  ) {
    self.word = word
    self.fontColor = fontColor
    self.fontString = fontString
    self.headwordSize = headwordSize
    self.showHeadword = showHeadword
    self.showDefinition = showDefinition
    self.showSentence = showSentence
    self.headwordOpacity = headwordOpacity
    self.definitionOpacity = definitionOpacity
    self.sentenceOpacity = sentenceOpacity
  }

  var body: some View {
    VStack(alignment: .center) {
      if showHeadword {
        WordHeadwordView(
          word: word,
          fontColor: fontColor,
          fontString: fontString
        )
        .opacity(headwordOpacity)
      }

      if showDefinition || showSentence {
        VStack() {
          if showDefinition {
            WordDefinitionView(
              word: word,
              fontColor: fontColor,
              fontString: fontString
            )
            .opacity(definitionOpacity)
          }

          if showSentence {
            WordSentenceView(
              word: word,
              fontColor: fontColor,
              fontString: fontString
            )
            .opacity(sentenceOpacity)
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
  }
}


// MARK: - Previews
struct SharedWordContent_Previews: PreviewProvider {
  static let sampleWord = Word(
    Rank: "1",
    List: "test",
    Headword: "myeloma",
    Definition: "A malignant tumor of bone marrow plasma cells. This is a longer definition to test how the view handles multiple lines of text.",
    Context_sentence: "The patient was diagnosed with multiple myeloma after extensive testing.",
    Synonyms: "plasma cell myeloma",
    Antonyms: "",
    Topic: "medical"
  )

  static var previews: some View {
    Group {
      // Full content preview
      SharedWordContent(
        word: sampleWord,
        fontColor: .black,
        fontString: "Georgia"
      )
      .previewDisplayName("Full Content")

      // Only headword
      SharedWordContent(
        word: sampleWord,
        fontColor: .black,
        fontString: "Georgia",
        showHeadword: true,
        showDefinition: false,
        showSentence: false
      )
      .previewDisplayName("Headword Only")

      // Definition and sentence
      SharedWordContent(
        word: sampleWord,
        fontColor: .black,
        fontString: "Georgia",
        showHeadword: false,
        showDefinition: true,
        showSentence: true
      )
      .previewDisplayName("Definition & Sentence")

      // Dark mode preview
      SharedWordContent(
        word: sampleWord,
        fontColor: .white,
        fontString: "Georgia"
      )
      .background(Color.black)
      .previewDisplayName("Dark Mode")

      // Individual components preview
      VStack(spacing: 20) {
        WordHeadwordView(
          word: sampleWord,
          fontColor: .black,
          fontString: "Georgia"
        )

        WordDefinitionView(
          word: sampleWord,
          fontColor: .black,
          fontString: "Georgia"
        )

        WordSentenceView(
          word: sampleWord,
          fontColor: .black,
          fontString: "Georgia"
        )
      }
      .previewDisplayName("Individual Components")

      // Different device sizes
      SharedWordContent(
        word: sampleWord,
        fontColor: .black,
        fontString: "Georgia"
      )
      .previewDevice("iPhone SE")
      .previewDisplayName("iPhone SE")

      SharedWordContent(
        word: sampleWord,
        fontColor: .black,
        fontString: "Georgia"
      )
      .previewDevice("iPad Pro (11-inch)")
      .previewDisplayName("iPad Pro")
    }
    .padding()
  }
}
