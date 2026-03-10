// LeaderboardView.swift
// Yap

import SwiftUI

struct LeaderboardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var selectedTab: LeaderboardTab = .global
    
    enum LeaderboardTab: String, CaseIterable {
        case global = "Global"
        case you = "You"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                boardPicker
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                switch selectedTab {
                case .global:
                    globalLeaderboardContent
                case .you:
                    yourLeaderboardContent
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
            .task {
                await viewModel.loadGlobalLeaderboard()
            }
        }
    }
    
    private var boardPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(LeaderboardTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Global Tab
    
    @ViewBuilder
    private var globalLeaderboardContent: some View {
        if viewModel.globalLeaderboard.isEmpty {
            ContentUnavailableView("No global data yet", image: "", description:
                Text("Missions from all users will appear here.")
            )
        } else {
            globalLeaderboardList
        }
    }
    
    private var globalLeaderboardList: some View {
        List {
            ForEach(Array(viewModel.globalLeaderboard.enumerated()), id: \.element.id) { index, stats in
                if let agent = stats.resolvedAgent {
                    NavigationLink {
                        AgentDetailView(agent: agent)
                            .environmentObject(viewModel)
                    } label: {
                        globalRow(index: index, stats: stats)
                    }
                } else {
                    globalRow(index: index, stats: stats)
                }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Your Tab
    
    @ViewBuilder
    private var yourLeaderboardContent: some View {
        if viewModel.agentLeaderboard.isEmpty {
            ContentUnavailableView("No missions yet", image: "", description:
                 Text("Complete your first mission to see agent performance.")
            )
        } else {
            userLeaderboardList
        }
    }
    
    private var userLeaderboardList: some View {
        List {
            ForEach(Array(viewModel.agentLeaderboard.enumerated()), id: \.element.id) { index, stats in
                NavigationLink {
                    AgentDetailView(agent: stats.agent)
                        .environmentObject(viewModel)
                } label: {
                    agentRow(stats: stats, index: index)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func agentRow(stats: AgentStats, index: Int) -> some View {
        HStack(spacing: 12) {
            Text(rankEmoji(for: index))
                .font(.system(size: 20))
                .frame(width: 30)
            
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
            
            Text(stats.successRateFormatted)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(rateColor(for: stats.successRate))
        }
    }
    
    // MARK: - Global Row
    
    private func globalRow(index: Int, stats: GlobalAgentStats) -> some View {
        HStack(spacing: 12) {
            Text(rankEmoji(for: index))
                .font(.system(size: 20))
                .frame(width: 30)
            
            Text(stats.resolvedAgent?.emoji ?? "❓")
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stats.resolvedAgent?.displayName ?? stats.agent)
                    .font(.system(size: 16, weight: .medium))
                
                HStack(spacing: 8) {
                    Text(stats.record)
                    Text("·")
                    Text("\(stats.totalUsers) users")
                    if stats.avgMinutes != nil {
                        Text("·")
                        Text("⌀ \(stats.avgTimeFormatted)")
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(stats.successRateFormatted)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(rateColor(for: stats.successRate))
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helpers
    
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
        case 80...100: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(HomeViewModel())
}
