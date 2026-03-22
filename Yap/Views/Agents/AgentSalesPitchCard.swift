//
//  AgentSalesPitchCard.swift
//  Yap
//
//  Created by Philipp Tschauner on 17.03.26.
//

import SwiftUI

struct AgentSalesPitchCard: View {
    let agent: Agent
    var showAurora = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AgentQuoteView(quote: agent.proPitch)
                .background(
                    ZStack {
                        if showAurora {
                            AuroraView(colors: agent.auroraColors)
                                .frame(width: 280, height: 280)
                        }
                    }
                )
            
            Text("— \(agent.displayName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .id("name-\(agent)")
                .transition(.opacity)
                .padding(.leading, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 30))
    }
}

struct AgentPitchCard: View {
    let agent: Agent
    var pitch: String?
    var showAurora = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AgentQuoteView(quote: pitch ?? agent.pitch)
                .background(
                    ZStack {
                        if showAurora {
                            AuroraView(colors: agent.auroraColors)
                                .frame(width: 280, height: 280)
                        }
                    }
                )
            
            Text("— \(agent.displayName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .id("name-\(agent)")
                .transition(.opacity)
                .padding(.leading, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 30))
    }
}

#Preview {
    AgentSalesPitchCard(agent: .ex)
}
