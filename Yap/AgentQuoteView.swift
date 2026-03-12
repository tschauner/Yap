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
    
    var body: some View {
        HStack(spacing: 15) {
            if showIcon {
                Image(icon: .quoteOpening)
                    .font(.system(size: 22))
                Text(quote)
                    .font(.system(size: 19, weight: .semibold))
                    .italic()
                    .multilineTextAlignment(.leading)
            } else {
                Text(quote)
                    .font(.system(size: 19, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    AgentQuoteView(quote: "This ia a sample text")
}
