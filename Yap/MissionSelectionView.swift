//
//  MissionSelectionView.swift
//  Yap
//
//  Created by Philipp Tschauner on 09.03.26.
//

import SwiftUI

struct MissionSelectionView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Namespace private var cardNamespace
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showAgents {
                if let locked = viewModel.pickerState.lockedAgent {
                    // Locked state: only selected card, centered
                    lockedCardView(agent: locked)
                        .transition(.opacity)
                } else {
                    // Selection state: all cards in scroll
                    Spacer()
                    
                    if let selectedAgent = viewModel.selectedAgent {
                        AgentCard(agent: selectedAgent, isSelected: true, cardSize: .big)
                            .matchedGeometryEffect(id: selectedAgent.id, in: cardNamespace)
                            .shadow(color: selectedAgent.accentColor.opacity(0.4), radius: 10, x: -10, y: 10)
                            .onTapGesture {
                                withAnimation(.snappy(extraBounce: 0.1)) {
                                    viewModel.selectedAgent = nil
                                }
                            }
                        
                        HStack(spacing: 15) {
                            Image(icon: .quoteOpening)
                                .font(.system(size: 22))
                            Text(selectedAgent.pitch)
                                .font(.system(size: 19, weight: .semibold))
                                .italic()
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 50)
                        .padding(.top)
//                        .animation(.easeOut, value: viewModel.isFocused)
                        

                            //.isVisible(!viewModel.isFocused)
                    } else {
                        Text("What are you avoiding? Pick an agent to fix it.")
                            .font(.system(size: 19, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 50)
                            .padding(.top)
                    }
                    
                    Spacer()
                    
                    AgentListView(cardNamespace: cardNamespace)
                        .frame(height: 120)
                        .scrollIndicators(.hidden)
                        .scrollTargetBehavior(.viewAligned)
                        .safeAreaPadding(.horizontal, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .isVisible(!viewModel.isFocused)
                }
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
//        .background(Color("purple").gradient)
        .onTapGesture {
            withAnimation {
                viewModel.isFocused = false
            }
        }
    }
    
    private func lockedCardView(agent: Agent) -> some View {
        VStack(spacing: 0) {
            Text(agent.emoji)
                .font(.system(size: 30, weight: .semibold))
                .matchedGeometryEffect(id: "agent_emoji", in: cardNamespace)
            Text(agent.displayName)
                .font(.system(size: 17, weight: .semibold))
                .padding(.top, 5)
                .matchedGeometryEffect(id: "agent_name", in: cardNamespace)
            
            // Subtitle: typing dots or reaction
            Group {
                switch viewModel.pickerState {
                case .reaction(_, let reaction):
                    Text(reaction)
                        .transition(.opacity)
                        .font(.system(size: 17, weight: .medium))
                        .multilineTextAlignment(.center)
                default:
                    TypingDotsView()
                        .transition(.opacity)
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.top, 10)
            .matchedGeometryEffect(id: "agent_subtitle", in: cardNamespace)
            .animation(.easeInOut(duration: 0.3), value: viewModel.pickerState)
        }
        .padding(15)
        .matchedGeometryEffect(id: agent.id, in: cardNamespace)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 100)
    }
}

#Preview {
    MissionSelectionView()
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
