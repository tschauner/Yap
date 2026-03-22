//
//  AgentListView.swift
//  Yap
//
//  Created by Philipp Tschauner on 09.03.26.
//

import SwiftUI

struct AgentListView: View {
    @EnvironmentObject var viewModel: MissionViewModel
    var cardNamespace: Namespace.ID
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .center) {
                ForEach(viewModel.orderAgentList()) { agent in
                    if viewModel.selectedAgent != agent {
                        agentCard(agent: agent)
                            .matchedGeometryEffect(id: agent.id, in: cardNamespace)
                            .onTapGesture {
                                if viewModel.selectedAgent != nil {
                                    // Step 1: animate old agent back to list
                                    withAnimation(.snappy(extraBounce: 0.1)) {
                                        viewModel.selectedAgent = nil
                                    }
                                    // Step 2: animate new agent to center
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        withAnimation(.snappy(extraBounce: 0.1)) {
                                            viewModel.selectedAgent = agent
                                        }
                                    }
                                } else {
                                    withAnimation(.snappy(extraBounce: 0.1)) {
                                        viewModel.selectedAgent = agent
                                    }
                                }
                        }
                    }
                }
                .scrollTargetLayout()
            }
        }
    }
    
    func agentCard(agent: Agent) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                AgentCircle(agent: agent)

                Text(agent.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40, alignment: .top)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
            }
            .contextMenu {
                if viewModel.favoriteAgent == agent {
                    ContextButton(title: L10n.Agents.removeFavorite, icon: .removeFavorite) {
                        viewModel.toggleFavorite(agent)
                    }
                } else {
                    ContextButton(title: L10n.Agents.setFavorite, icon: .star) {
                        viewModel.toggleFavorite(agent)
                    }
                }
                
                ContextButton(title: L10n.Agents.dismissAgent, icon: .eyeSlash, role: .destructive) {
                    viewModel.dismissAgent(agent)
                }
            }
            
            Spacer()
        }
        .frame(width: 70, height: 90)
    }
}
