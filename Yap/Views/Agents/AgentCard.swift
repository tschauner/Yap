//
//  AgentCard.swift
//  Yap
//
//  Created by Philipp Tschauner on 09.03.26.
//

import SwiftUI

enum AgentCardSize {
    case big
    case small
    
    var frame: CGSize {
        switch self {
        case .small:
            .init(width: 70, height: 90)
        case .big:
            .init(width: 150, height: 90)
        }
    }
    
    var scale: Double {
        switch self {
        case .small:
            1.0
        case .big:
            1.05
        }
    }
}

struct AgentCard: View {
    var agent: Agent
    var isSelected: Bool = false
    var isFloading: Bool = false
    var cardSize: AgentCardSize = .small
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AgentCircle(agent: agent)
                    .scaleEffect(cardSize.scale)
                
                if isSelected {
                    Image(icon: .minus)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 25, height: 25)
                        .background(Color(.systemGray2))
                        .clipShape(Circle())
                        .zIndex(1)
                        .offset(x: 10, y: -5)
                }
            }
            .floatingEffect(enabled: isFloading)

            Text(agent.displayName)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 40, alignment: .top)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            
            Spacer()
        }
        .frame(width: cardSize.frame.width, height: cardSize.frame.height)
    }
}

#Preview {
    AgentCard(agent: .mom, isSelected: true, isFloading: true)
}
