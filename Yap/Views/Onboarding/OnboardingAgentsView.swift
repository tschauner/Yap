//
//  AgentsOnboardingView.swift
//  Yap
//
//  Created by Philipp Tschauner on 16.03.26.
//

import SwiftUI

struct OnboardingAgentsView: View {
    @Binding var selectedAgent: Agent?
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0) {
            if let selectedAgent {
                VStack(spacing: 0) {
                    AgentCircle(agent: selectedAgent, isSelected: true)
                        .offset(y: 10)
                        .floatingEffect(enabled: true)
                        .zIndex(1)
                        .matchedGeometryEffect(id: selectedAgent.id, in: namespace)
                        .shadow(color: selectedAgent.accentColor.opacity(0.4), radius: 10, x: -10, y: 10)
                        .onTapGesture {
                            withAnimation(.snappy(extraBounce: 0.1)) {
                                self.selectedAgent = nil
                            }
                        }
                    
                    AgentPitchCard(agent: selectedAgent)
                        .padding(.horizontal, 40)
                }
                .frame(height: 200)
                .padding(.bottom, 50)
            } else {
                VStack {
                    VStack(spacing: 0) {
                        Headline(text: L10n.Onboarding.agentsHeadline)
                            .background(
                                AuroraView()
                                    .frame(width: 280, height: 280)
                                    .opacity(0.7)
                                    .allowsHitTesting(false)
                            )
                        
                        Subline(text: L10n.Onboarding.agentsSubline)
                            .padding(.top, 15)
                    }
                }
                .frame(height: 200)
                .padding(.bottom, 50)
                .padding(.horizontal, .horizontal)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 30) {
                ForEach(Agent.standard, id: \.self) { agent in
                    if selectedAgent != agent {
                        AgentCard(agent: agent)
                            .matchedGeometryEffect(id: agent.id, in: namespace)
                            .onTapGesture {
                                withAnimation(.snappy(extraBounce: 0.1)) {
                                    self.selectedAgent = agent
                                }
                            }
                        }
                }
            }
            .padding(.horizontal, .horizontal)
        }
    }
}

#Preview {
    struct AgentsContainer: View {
        @Namespace var namespace
        @State var selectedAgent: Agent?
        
        var body: some View {
            OnboardingAgentsView(
                selectedAgent: $selectedAgent,
                namespace: namespace
            )
        }
    }
   return AgentsContainer()
}
