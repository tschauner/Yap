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
                    .animation(.easeOut, value: viewModel.phase)
            }
            .task {
                await viewModel.onAppear()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let appURL = viewModel.appURL, let appName = Bundle.main.appName {
                        ShareLink(item: appURL, message: .init("L10n.About.shareApp(appName)")) {
                            Image(icon: .share)
                                .offset(y: -2)
                        }
                    }
                }
                //.sharedBackgroundVisibility(.hidden)
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 5) {
                        Text("Achievements")
                            .font(.caption)
                    }
                    .frame(height: 30)
                    .padding(.horizontal, 10)
                    .background(.quinary)
                    .clipShape(Capsule())
                    .onTapGesture {
                        showLeaderboard = true
                    }
                }
               // .sharedBackgroundVisibility(.hidden)
                
                ToolbarItem(placement: .topBarTrailing) {
                    settingsMenu
                }
                //.sharedBackgroundVisibility(.hidden)
            }
            .hapticFeedback(trigger: viewModel.selectedAgent)
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
            .navigationDestination(isPresented: $viewModel.showAgentPacks) {
                AgentPackView()
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
            ActiveMissionView(mission: mission, cardNamespace: cardNamespace)
        case .selection:
            MissionSelectionView(cardNamespace: cardNamespace)
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
