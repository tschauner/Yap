//
//  Headline.swift
//  Yap
//
//  Created by Philipp Tschauner on 17.03.26.
//

import SwiftUI

struct Headline: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 30, weight: .heavy))
            .fontDesign(.rounded)
//            .italic()
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    Headline(text: "Pick who nags you.")
}
