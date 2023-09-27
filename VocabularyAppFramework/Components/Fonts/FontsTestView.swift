//
//  FontsTestView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 27/09/2023.
//

import SwiftUI

struct FontsTestView: View {
    var body: some View {
        VStack {
            Text("Hello, world!")
                .font(.custom("Verdana", size: 20))
            
            Text("Hello, world!")
                .font(.custom("AmericanTypewriter", size: 20))
            
            Text("Hello, world!")
                .font(.custom("AcademyEngravedLetPlain", size: 30))
        }
        .onAppear {
            for family in UIFont.familyNames.sorted() {
                let names = UIFont.fontNames(forFamilyName: family)
                print("Family: \(family) Font names: \(names)")
            }
        }
    }
}

struct FontsTestView_Previews: PreviewProvider {
    static var previews: some View {
        FontsTestView()
    }
}
