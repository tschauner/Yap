//
//  MissionView.swift
//  Yap
//
//  Created by Philipp Tschauner on 04.03.26.
//

import SwiftUI

struct MissionView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @State var isActive = false
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var showHelp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
                    //.animation(.easeOut, value: isActive)
                    .animation(.easeOut, value: viewModel.phase)
            }
            .task {
                await viewModel.onAppear()
            }
            .sheet(item: $viewModel.selectedMission) { mission in
                AgentPicker(mission: mission)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(icon: viewModel.appearance == .dark ? .sun : .moon)
                        .contentTransition(.symbolEffect)
                        .foregroundStyle(.secondary)
                        .button {
                            viewModel.toggleAppearance()
                        }
                }
                .sharedBackgroundVisibility(.hidden)
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 5) {
//                        Image(icon: .flame)
//                            .font(.caption)
//                            .foregroundStyle(.primary)
                        Text("Achievements")
                            .font(.caption)
                    }
                    .frame(height: 30)
                    .padding(.horizontal, 10)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Capsule())
                    .onTapGesture {
                        showLeaderboard = true
                    }
                }
                .sharedBackgroundVisibility(.hidden)
                
                ToolbarItem(placement: .topBarTrailing) {
                    settingsMenu
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .sheet(isPresented: $showLeaderboard) {
                LeaderboardView()
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView()
            }
        }
    }
    
    private func openMail() {
        let email = "support@yapapp.com"
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    @ViewBuilder
    var content: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView()
        case .activeMission(let mission), .completed(let mission):
            ActiveMissionView(mission: mission)
        case .selection:
            selectionView
        case .gaveUp(let mission):
            Text("Mission failed")
        }
    }
    
    let rows = [GridItem(.fixed(100))]
    @Environment(\.colorScheme) var colorScheme
    
    var selectionBackgroundColor: Color {
        colorScheme == .light ? Color.blue.opacity(0.1) : Color.orange.opacity(0.15)
    }
    
    var selectionBorderColor: Color {
        colorScheme == .light ? Color.blue : Color.orange
    }
    
    var selectionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("At your service")
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, 5)
                .padding(.leading, 20)
            
            ScrollView(.horizontal) {
                LazyHGrid(rows: rows) {
                    ForEach(viewModel.orderAgentList(), id: \.self) { agent in
                        VStack(spacing: 0) {
                            Text(agent.emoji)
                                .font(.system(size: 26))
                            Text(agent.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.bottom, 10)
                                .padding(.top, 5)
                            Text(viewModel.stats(for: agent).successRateFormatted)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 100, height: 100)
                        .background(viewModel.selectedAgent == agent ? selectionBackgroundColor : nil)
                        .cornerRadius(20)
                        .roundedOutline(lineWidth: colorScheme == .light && viewModel.selectedAgent == agent ? 1.5 : 1, cornerRadius: 20, color: viewModel.selectedAgent == agent ? selectionBorderColor : Color(.quaternaryLabel))
                        .onTapGesture {
                            viewModel.selectedAgent = agent
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            
            Spacer()
            
            InputTextfield()
                .padding(15)
                .glassEffect(in: .rect(cornerRadius: 20))
                .padding(.bottom, 20)
                .transition(.opacity)
                .padding(.horizontal, 20)
        }
    }
    
    var settingsMenu: some View {
        Menu {
            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            
            Button {
                viewModel.showPaywall = true
            } label: {
                Label("Upgrade Plan", systemImage: "star")
            }
            
            Divider()
            
            Button {
                showHelp = true
            } label: {
                Label("Help & Support", systemImage: "questionmark.circle")
            }
        } label: {
            Image(icon: .ellipsis)
        }
    }
    
    var taskList: some View {
        List {
            ForEach(viewModel.queuedMissions) { mission in
                missionRow(for: mission)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.removeMissionFromQueue(mission)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedMission = mission
                    }
            }
        }
        .listStyle(.plain)
    }
    
    func missionRow(for mission: MissionItem) -> some View {
        HStack {
            Text(mission.title)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.selectedMission == mission ? "selected" : "queued")
                .foregroundStyle(viewModel.selectedMission == mission ? .blue : .secondary)
                .font(.caption)
        }
    }
}

#Preview {
    struct MissionContainer: View {
        @StateObject var viewModel = HomeViewModel()
        var body: some View {
            MissionView()
                .environmentObject(viewModel)
        }
    }
    
    return MissionContainer()
}

extension View {
    func button(_ action: @escaping () -> Void) -> some View {
        modifier(ButtonModifier(action: action))
    }
}

struct ButtonModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        Button(action: action) {
            content
        }
    }
}
