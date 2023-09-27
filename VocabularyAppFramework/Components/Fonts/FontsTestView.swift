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
                .font(.custom("Item 0", size: 20))
            
            Text("Hello, world!")
                .font(.custom("Item 1", size: 20))
        }
    }
}

struct FontsTestView_Previews: PreviewProvider {
    static var previews: some View {
        FontsTestView()
    }
}
