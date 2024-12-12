//
//  PoppingEmoji.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 02/11/2023.
//

import SwiftUI

struct PoppingEmoji: View {
    
    @State var startValue: CGFloat = 1
    @Binding var isTrigger : Bool
    let maxValue : CGFloat = 250
    
    var body: some View {
        
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: startValue))
                .padding(5)
                .background(isTrigger ? Color.main.opacity(0.1) : .clear)
                .clipShape(Circle())
                .foregroundStyle(.main, .white)
        }
        .onChange(of: isTrigger) { _,  oldValue in
            updateScaleValue()
        }
        .onTapGesture {
            updateScaleValue()
        }
    }
    
    func updateScaleValue() {
        withAnimation(.bouncy) {
            if startValue == 1 || startValue == 20 {
                startValue = maxValue
            } else if startValue == maxValue {
                startValue = 20
            }
        }
    }
}

#Preview {
    PoppingEmoji(isTrigger: .constant(false))
}
