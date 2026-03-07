// LeaderboardView.swift
// Yap

import SwiftUI

struct LeaderboardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.agentLeaderboard.isEmpty {
                    emptyState
                } else {
                    leaderboardList
                }
            }
            .navigationTitle("Agent Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("🏆")
                .font(.system(size: 48))
            
            Text("No missions yet")
                .font(.system(size: 17, weight: .medium))
            
            Text("Complete your first mission to see agent performance.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var leaderboardList: some View {
        List {
            ForEach(Array(viewModel.agentLeaderboard.enumerated()), id: \.element.id) { index, stats in
                NavigationLink {
                    AgentDetailView(agent: stats.agent)
                        .environmentObject(viewModel)
                } label: {
                    HStack(spacing: 12) {
                        // Rank
                        Text(rankEmoji(for: index))
                            .font(.system(size: 20))
                            .frame(width: 30)
                        
                        // Agent
                        Text(stats.agent.emoji)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stats.agent.displayName)
                                .font(.system(size: 16, weight: .medium))
                            Text(stats.record)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Success rate
                        Text(stats.successRateFormatted)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(rateColor(for: stats.successRate))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func rankEmoji(for index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(index + 1)."
        }
    }
    
    private func rateColor(for rate: Double?) -> Color {
        guard let rate else { return .secondary }
        switch rate {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(HomeViewModel())
}
