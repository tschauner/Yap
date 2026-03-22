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
            } else {
                Text(quote)
                    .font(.system(size: isBig ? 26 : 19, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    AgentQuoteView(quote: "This ia a sample text")
}
