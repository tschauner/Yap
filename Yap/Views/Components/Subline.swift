//
//  Subline.swift
//  Yap
//
//  Created by Philipp Tschauner on 18.03.26.
//

import SwiftUI

struct Subline: View {
    let text: String
    var size: CGFloat = 17
    
    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .font(.system(size: size, weight: .regular))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    Subline(text: "This is a subline")
}
