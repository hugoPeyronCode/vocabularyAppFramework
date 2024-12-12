//
//  QCMView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 28/10/2023.
//

import SwiftUI

struct QCMView: View {
    
    @StateObject var vm: ViewModel
    
    @State var selectedAnswer : [String] = []
    @State var isActive : Bool = false
    @State var isGoodAnswer : Bool = false
    @State var isBadAnswer : Bool = false
    
    let fontColor : Color
    let fontString : String
    
    init(word: Word, fontColor: Color, fontString: String) {
        _vm = StateObject(wrappedValue: ViewModel(word: word))
        self.fontColor = fontColor
        self.fontString = fontString
    }
    
    var body: some View {
        ZStack {
            VStack {
                    WordDescription
                    .offset(y: -20)
                    .padding()
                
                    QuestionButtons
                    .shake($isBadAnswer)
                
                    ValidationButton
                    .offset(y: 50)
                    
                }
                .foregroundColor(fontColor)
            
                PoppingEmoji(isTrigger: $isGoodAnswer)
        }
        .sensoryFeedback(.impact, trigger: isGoodAnswer)
        .sensoryFeedback(.error, trigger: isBadAnswer)
    }
    
    var WordDescription : some View {
        Text(vm.cleanWordDescription(word: vm.word))
            .lineLimit(nil)
            .multilineTextAlignment(.center)
            .font(.custom(fontString, size: 19))
    }
    
    var QuestionButtons : some View {
        ForEach(vm.similarWordsArray, id: \.self) { word in
            SingleSelectButton(content: word.capitalized, defaultColor: fontColor, fontString: fontString, selectedItems: $selectedAnswer) {
                    // some action here
                    isActive = true
                }
                .disabled(isGoodAnswer)
        }
    }
    
    var ValidationButton : some View {
        MoveToNextPageButton(content: isGoodAnswer ? "Good Answer" : "Find the answer", icon: isGoodAnswer ? "party.popper" : "magnifyingglass", defaultColor: fontColor, fontString: fontString, isActive: $isActive, action: {
            checkAnswer()
        })
        .disabled(isGoodAnswer)
    }
    
    func checkAnswer() {
        isBadAnswer = false
        if selectedAnswer.first?.capitalized == vm.word.Headword.capitalized {
            isGoodAnswer = true
            print("Good answer!")
        } else {
            print("Bad Answer")
            isBadAnswer = true
        }
    }
}

#Preview {
    QCMView(word: Word(Rank: "1",
                       List: "Vocabulary",
                       Headword: "Philanthrope",
                       Definition: "Une personne qui cherche à promouvoir le bien-être d'autrui, en particulier par le don généreux d'argent à des causes bénéfiques. Et même bien plus car je dois verifier si le text même très grand rentre dans le carde de l'écran.",
                       Context_sentence: "Le philanthrope a fait un don de plusieurs millions à l'hôpital local.",
                       Synonyms: "Bienfaiteur, Donateur",
                       Antonyms: "Misanthrope, Égoïste",
                       Topic: "Société"), fontColor: .black, fontString: "basic")
}
