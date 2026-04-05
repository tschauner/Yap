//
//  AgentQuoteView.swift
//  Yap
//
//  Created by Philipp Tschauner on 10.03.26.
//

import SwiftUI

struct AgentQuoteView: View {
    let quote: String
    var showIcon: Bool = true
    var isBig = false
    
    var body: some View {
        HStack(spacing: 15) {
            if showIcon {
                Image(icon: .quoteClosing)
                    .font(.system(size: isBig ? 34 : 22))
                Text(quote)
                    .font(.system(size: isBig ? 30 : 19, weight: .semibold))
                    .italic()
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(quote)
            } else {
                Text(quote)
                    .font(.system(size: isBig ? 26 : 19, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(quote)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: quote)
    }
}

#Preview {
    AgentQuoteView(quote: "This ia a sample text")
}
