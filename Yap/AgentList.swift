//
//  AgentList.swift
//  Yap
//
//  Created by Philipp Tschauner on 05.03.26.
//

import SwiftUI

struct AgentList: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        agentList
    }
    
    @ViewBuilder
    private var agentList: some View {
        let orderedAgents = viewModel.orderAgentList()

        ScrollView {
            VStack(spacing: 0) {
                ForEach(orderedAgents, id: \.self) { agent in
                    let stats = viewModel.stats(for: agent)
                    
                    HStack(spacing: 10) {
                        Text(agent.emoji)
                            .font(.system(size: 19, weight: .medium))
                        Text(agent.displayName)
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Success rate
                        Text(stats.successRateFormatted)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        
    //                    if isSelected(agent) {
    //                        Image(icon: .checkmark)
    //                    }
                    }
                    .frame(height: 45)
                    .contentShape(Rectangle())
                    .background(isSelected(agent) ? Color.blue.opacity(0.05) : .clear)
                    .onTapGesture {
                        withAnimation(.snappy(extraBounce: 0.1)) {
                            viewModel.showAgents = false
                            viewModel.selectedAgent = agent
                        } completion: {
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    private func isSelected(_ agent: Agent) -> Bool {
        viewModel.selectedAgent == agent
    }
}

#Preview {
    struct AgentlistContainer: View {
        @StateObject var viewModel = HomeViewModel()
        
        var body: some View {
            AgentList()
                .environmentObject(viewModel)
        }
    }
    
    return AgentlistContainer()
}
