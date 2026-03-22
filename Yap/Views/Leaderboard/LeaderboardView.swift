// LeaderboardView.swift
// Yap

import SwiftUI

struct LeaderboardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MissionViewModel
    @State private var selectedTab: LeaderboardTab = .global
    
    enum LeaderboardTab: String, CaseIterable {
        case global = "Global"
        case you = "You"
        
        var localizedName: String {
            switch self {
            case .global: return L10n.Leaderboard.tabGlobal
            case .you: return L10n.Leaderboard.tabYou
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                boardPicker
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                switch selectedTab {
                case .global:
                    globalLeaderboardContent
                case .you:
                    yourLeaderboardContent
                }
            }
            .navigationTitle(L10n.Leaderboard.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Image(icon: .close)
                        .button {
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
                Text(tab.localizedName).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Global Tab
    
    @ViewBuilder
    private var globalLeaderboardContent: some View {
        if viewModel.globalLeaderboard.isEmpty {
            ContentUnavailableView(L10n.Leaderboard.globalEmptyTitle, image: "", description:
                Text(L10n.Leaderboard.globalEmptyDescription)
            )
        } else {
            globalLeaderboardList
        }
    }
    
    private var globalLeaderboardList: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(Array(viewModel.globalLeaderboard.enumerated()), id: \.element.id) { index, stats in
                    if let agent = stats.resolvedAgent {
                        NavigationLink {
                            AgentDetailView(agent: agent)
                                .environmentObject(viewModel)
                        } label: {
                            globalRow(index: index, stats: stats)
                        }
                        .buttonStyle(.plain)
                    } else {
                        globalRow(index: index, stats: stats)
                    }
                }
            }
            .padding(.horizontal, .horizontal)
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Your Tab
    
    @ViewBuilder
    private var yourLeaderboardContent: some View {
        if viewModel.agentLeaderboard.isEmpty {
            ContentUnavailableView(L10n.Leaderboard.youEmptyTitle, image: "", description:
                 Text(L10n.Leaderboard.youEmptyDescription)
            )
        } else {
            userLeaderboardList
        }
    }
    
    private var userLeaderboardList: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(Array(viewModel.agentLeaderboard.enumerated()), id: \.element.id) { index, stats in
                    NavigationLink {
                        AgentDetailView(agent: stats.agent)
                            .environmentObject(viewModel)
                    } label: {
                        agentRow(stats: stats, index: index)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .horizontal)
        }
        .scrollIndicators(.hidden)
    }
    
    private func agentRow(stats: AgentStats, index: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(index + 1)")
                .font(.system(size: 18, weight: .black))
                .padding(.trailing, 20)
            AgentCircle(agent: stats.agent)
                .padding(.trailing, 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stats.agent.displayName)
                    .font(.system(size: 17, weight: .semibold))
                Text(stats.record)
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(stats.successRateFormatted)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(rateColor(for: stats.successRate))
                .fontWeight(.bold)
                .fontDesign(.rounded)
        }
        .contentShape(Rectangle())
//        .background(index == 0 ? Color.black.opacity(0.8) : .clear)
    }
    
    // MARK: - Global Row
    
    private func globalRow(index: Int, stats: GlobalAgentStats) -> some View {
        HStack(spacing: 0) {
            Text("\(index + 1)")
                .font(.system(size: 18, weight: .black))
                .padding(.trailing, 20)
            
            AgentCircle(agent: stats.resolvedAgent ?? .mom)
                .padding(.trailing, 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stats.resolvedAgent?.displayName ?? stats.agent)
                    .font(.system(size: 17, weight: .semibold))
                HStack(spacing: 5) {
                    Text(L10n.Leaderboard.users(stats.totalUsers))
                    if stats.avgMinutes != nil {
                        Text("·")
                        Text("⌀ \(stats.avgTimeFormatted)")
                    }
                }
                .font(.system(size: 12))
                .fontWeight(.heavy)
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
                
                Text(stats.record)
                    .font(.system(size: 12))
                    .fontWeight(.heavy)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(stats.successRateFormatted)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(rateColor(for: stats.successRate))
                .fontWeight(.bold)
                .fontDesign(.rounded)
        }
    }
    
    // MARK: - Helpers
    
    private func rateColor(for rate: Double?) -> Color {
        guard let rate else { return .secondary }
        switch rate {
        case 0.8...1:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(MissionViewModel())
}
