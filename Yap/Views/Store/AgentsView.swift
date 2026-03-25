// AgentsView.swift
// Yap

import SwiftUI

struct AgentsView: View {
    @EnvironmentObject var viewModel: MissionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAgent: Agent?

    private let columns = [GridItem(.flexible()),
                           GridItem(.flexible()),
                           GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                agentGrid
                    .padding(.horizontal, .horizontal)
            }
            .navigationTitle(L10n.Agents.title)
            .navigationBarTitleDisplayMode(.inline)
            .hapticFeedback(trigger: selectedAgent)
        }
    }
    
    private var agentGrid: some View {
        VStack(spacing: 0) {
            // Selected agent detail
            if let agent = selectedAgent {
                VStack(spacing: 0) {
                    AgentPitchCard(agent: agent)
                        .background(
                            AuroraView()
                                .frame(width: 280, height: 280)
                                .opacity(0.7)
                                .allowsHitTesting(false)
                        )
                        .padding(.horizontal, 20)
                    
                    // Stats chips
                    HStack(spacing: 8) {
                        statChip(icon: .bolt, label: agent.intensityLabel)
                        statChip(icon: .quoteClosing, label: agent.styleTag)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .frame(height: 200)
                .padding(.top, 30)
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    Headline(text: L10n.Agents.headline)
                        .padding(.top, 10)
                    Subline(text: L10n.Agents.subline, size: 17)
                        .padding(.top, 15)
                    
                    Spacer()
                }
                .frame(height: 200)
                .padding(.horizontal, .horizontal)
                .padding(.top, 30)
            }
            
            // Base agents
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Agent.allCases, id: \.self) { agent in
                    AgentBubble(agent: agent, isSelected: agent == selectedAgent, isDismissed: viewModel.isDismissed(agent))
                        .contextMenu {
                            if viewModel.isDismissed(agent) {
                                ContextButton(title: L10n.Agents.deployAgent, icon: .eye) {
                                    viewModel.deployAgent(agent)
                                }
                            } else {
                                ContextButton(title: L10n.Agents.dismissAgent, icon: .eyeSlash, role: .destructive) {
                                    viewModel.dismissAgent(agent)
                                }
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedAgent = selectedAgent == agent ? nil : agent
                            }
                        }
                }
            }
        }
    }
    
    private func statChip(icon: SystemImage, label: String) -> some View {
        HStack(spacing: 4) {
            Image(icon: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.quaternary, in: Capsule())
    }
    
    private func sectionHeader(title: String) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(.secondary)
                .padding(.top, 15)
                .padding(.bottom, 7)
            
        Text(L10n.Agents.specialDescription)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 5)
        .padding(.bottom, 15)
    }
}

// MARK: - Agent Bubble

private struct AgentBubble: View {
    let agent: Agent
    var isSelected: Bool = false
    var isDismissed: Bool = false

    var body: some View {
        VStack(spacing: 6) {
           AgentCircle(agent: agent)
                .opacity(isDismissed ? 0.3 : 1.0)
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(agent.accentColor, lineWidth: 2)
                            .frame(width: 67, height: 67)
                    }
                }

            Text(agent.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isDismissed ? .tertiary : .primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

// MARK: - Preview

#Preview {
    AgentsView()
}
