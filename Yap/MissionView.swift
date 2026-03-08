//
//  MissionView.swift
//  Yap
//
//  Created by Philipp Tschauner on 04.03.26.
//

import SwiftUI

struct MissionView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Namespace private var cardNamespace
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
            .navigationBarTitleDisplayMode(.inline)
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
            if viewModel.showAgents {
                if let locked = viewModel.pickerState.lockedAgent {
                    // Locked state: only selected card, centered
                    lockedCardView(agent: locked)
                        .transition(.opacity)
                } else {
                    // Selection state: all cards in scroll
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(viewModel.orderAgentList()) { agent in
                                agentCard(agent: agent)
                                    .roundedOutline(cornerRadius: 25, color: viewModel.selectedAgent == agent ? .primary : .clear)
                                    .matchedGeometryEffect(id: agent.id, in: cardNamespace)
                                    .onTapGesture {
                                        viewModel.selectedAgent = agent
                                    }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            } else {
                Spacer()
            }
            
            if viewModel.pickerState.lockedAgent == nil {
                InputTextfield()
                    .padding(15)
                    .glassEffect(in: .rect(cornerRadius: 20))
                    .padding(.bottom, 20)
                    .transition(.opacity)
                    .padding(.horizontal, 20)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.pickerState)
    }
    
    // MARK: - Agent Card
    
    private func agentCard(agent: Agent) -> some View {
        VStack(spacing: 0) {
            Text(agent.emoji)
                .font(.system(size: 30, weight: .semibold))
            Text(agent.displayName)
                .font(.system(size: 17, weight: .semibold))
                .padding(.top, 5)
            
            Text(agent.pitch)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.top, 10)
        }
        .padding(15)
        .frame(width: 300, height: 150)
        .background(RoundedRectangle(cornerRadius: 25)
            .fill(Color(.quaternaryLabel).gradient)
        )
    }
    
    private func lockedCardView(agent: Agent) -> some View {
        VStack(spacing: 0) {
            Text(agent.emoji)
                .font(.system(size: 30, weight: .semibold))
            Text(agent.displayName)
                .font(.system(size: 17, weight: .semibold))
                .padding(.top, 5)
            
            // Subtitle: typing dots or reaction
            Group {
                switch viewModel.pickerState {
                case .reaction(_, let reaction):
                    Text(reaction)
                        .transition(.opacity)
                default:
                    TypingDotsView()
                        .transition(.opacity)
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.top, 10)
            .animation(.easeInOut(duration: 0.3), value: viewModel.pickerState)
        }
        .padding(15)
        .frame(width: 300, height: 150)
        .background(RoundedRectangle(cornerRadius: 25)
            .fill(Color(.quaternaryLabel).gradient)
        )
        .matchedGeometryEffect(id: agent.id, in: cardNamespace)
        .frame(maxWidth: .infinity)
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
