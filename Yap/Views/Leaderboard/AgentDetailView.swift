// AgentDetailView.swift
// Yap

import SwiftUI

struct AgentDetailView: View {
    @EnvironmentObject var viewModel: MissionViewModel
    let agent: Agent
    
    private var missions: [Mission] {
        viewModel.missions(for: agent)
    }
    
    private var stats: AgentStats {
        viewModel.stats(for: agent)
    }
    
    var body: some View {
        List {
            // Header with stats
            Section {
                VStack(spacing: 16) {
                    AgentCard(agent: agent)
                    
                    HStack(spacing: 32) {
                        statBadge(value: "\(stats.completed)", label: L10n.AgentDetail.completed, color: .green)
                        statBadge(value: "\(stats.givenUp)", label: L10n.AgentDetail.failed, color: .red)
                        statBadge(value: stats.successRateFormatted, label: L10n.AgentDetail.success, color: .blue)
                    }
                    .padding(20)
                    .glassEffect(in: .rect(cornerRadius: 20))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            }
            .listRowBackground(Color.clear)
            
            // Mission list
            Section {
                if missions.isEmpty {
                    Text(L10n.AgentDetail.noMissions)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    ForEach(missions) { mission in
                        missionRow(mission)
                    }
                }
            } header: {
                Text(L10n.AgentDetail.missions)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(agent.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func statBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
    
    private func missionRow(_ mission: Mission) -> some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: mission.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(mission.status == .completed ? .green : .red)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mission.title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(2)
                
                Text(mission.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Duration
            Text(mission.durationFormatted)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AgentDetailView(agent: .mom)
            .environmentObject(MissionViewModel())
    }
}
