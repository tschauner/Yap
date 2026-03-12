//
//  MissionSelectionView.swift
//  Yap
//
//  Created by Philipp Tschauner on 09.03.26.
//

import SwiftUI

struct MissionSelectionView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    var cardNamespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showAgents {
                Spacer()
                
                if let selectedAgent = viewModel.selectedAgent {
                    AgentCard(
                        agent: selectedAgent,
                        isSelected: true,
                        isFloading: true,
                        cardSize: .big
                    )
                    .matchedGeometryEffect(id: selectedAgent.id, in: cardNamespace)
                    .shadow(color: selectedAgent.accentColor.opacity(0.4), radius: 10, x: -10, y: 10)
                    .onTapGesture {
                        withAnimation(.snappy(extraBounce: 0.1)) {
                            viewModel.selectedAgent = nil
                        }
                    }
                }
                
                AgentQuoteView(quote: viewModel.selectedAgent?.pitch ?? "What are you avoiding?\nPick an agent to fix it.", showIcon: viewModel.selectedAgent != nil)
                    .padding(.horizontal, 50)
                    .padding(.top)
                    .background(
                        AuroraView()
                            .frame(width: 280, height: 280)
                            .opacity(0.7)
                            .allowsHitTesting(false)
                    )
                
                Spacer()
                
                HStack {
                    Text("Agents")
                        .font(.system(size: 15, weight: .medium))
                    
                    Spacer()
                    
                    Text("Show more")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 14, weight: .medium))
                        .button {
                            viewModel.showAgentPacks = true
                        }
                }
                .isVisible(!viewModel.isFocused)
                .padding(.bottom, 18)
                .padding(.trailing, 20)
                .padding(.leading, 50)
                
                AgentListView(cardNamespace: cardNamespace)
                    .frame(height: 120)
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .isVisible(!viewModel.isFocused)
            } else {
                Spacer()
            }
            
            if viewModel.pickerState.lockedAgent == nil {
                InputTextfield()
                    .padding(15)
                //                    .background(Color("purpleDark"), in: .rect(cornerRadius: 20))
                    .glassEffect(.clear, in: .rect(cornerRadius: 20))
                    .padding(.bottom, 20)
                    .transition(.opacity)
                    .padding(.horizontal, 20)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.pickerState)
        .onTapGesture {
            withAnimation {
                viewModel.isFocused = false
            }
        }
    }
}

#Preview {
    struct MissionSelectionContainerView: View {
        @StateObject var viewModel = HomeViewModel()
        @Namespace var namespace
        
        var body: some View {
            MissionSelectionView(cardNamespace: namespace)
                .environmentObject(viewModel)
        }
    }
    
    return MissionSelectionContainerView()
}

struct AgentCircle: View {
    let agent: Agent
    
    var body: some View {
        Circle()
            .frame(width: 60, height: 60)
            .foregroundStyle(agent.accentColor.gradient)
            .overlay(
                Text(agent.emoji)
                    .font(.system(size: 40, weight: .semibold))
            )
    }
}
