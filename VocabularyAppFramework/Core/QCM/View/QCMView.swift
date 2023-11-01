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
    
    let fontColor : Color
    let fontString : String
    
    init(word: Word, fontColor: Color, fontString: String) {
        _vm = StateObject(wrappedValue: ViewModel(word: word))
        self.fontColor = fontColor
        self.fontString = fontString
    }
    
    var body: some View {
            VStack {
                VStack{}
                    .frame(height: 50)
                
                Text(vm.cleanWordDescription(word: vm.word))
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .font(.custom(fontString, size: 19))
                    .padding()
                
//                Text("\(selectedAnswer.debugDescription)")
//                Text(vm.word.Headword)
            
                VStack{}
                    .frame(height: 50)
                
                ForEach(vm.similarWordsArray, id: \.self) { word in
                    SingleSelectButton(content: word.capitalized, defaultColor: fontColor, fontString: fontString, selectedItems: $selectedAnswer) {
                            // some action here
                            isActive = true
                        }
                        .disabled(isGoodAnswer)
                }
                
                VStack{}
                    .frame(height: 50)
                
                MoveToNextPageButton(content: isGoodAnswer ? "Good Answer" : "Find the answer", icon: isGoodAnswer ? "party.popper" : "magnifyingglass", defaultColor: fontColor, fontString: fontString, isActive: $isActive, action: {
                    checkAnswer()
                })
                .disabled(isGoodAnswer)
                .padding()
                
            }
            .foregroundColor(fontColor)
    }
    
    var Icon: some View {
        Image(systemName:"checkmark.circle.fill")
            .font(.title)
            .padding()
            .background(.clear)
            .clipShape(Circle())
            .foregroundStyle(.main)
            .padding()
    }
    
    func checkAnswer() {
        if selectedAnswer.first?.capitalized == vm.word.Headword.capitalized {
            isGoodAnswer = true
            print("Good answer!")
            HapticManager.shared.generateFeedback(for: .successStrong)
        } else {
            print("Bad Answer")
            HapticManager.shared.generateFeedback(for: .errorLight)

        }
    }
}

#Preview {
    QCMView(word: Word(Rank: "1",
                       List: "Vocabulary",
                       Headword: "Philanthrope",
                       Definition: "Une personne qui cherche à promouvoir le bien-être d'autrui, en particulier par le don généreux d'argent à des causes bénéfiques.",
                       Context_sentence: "Le philanthrope a fait un don de plusieurs millions à l'hôpital local.",
                       Synonyms: "Bienfaiteur, Donateur",
                       Antonyms: "Misanthrope, Égoïste",
                       Topic: "Société"), fontColor: .black, fontString: "basic")
}
