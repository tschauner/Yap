//
//  MissionView.swift
//  Yap
//
//  Created by Philipp Tschauner on 04.03.26.
//

import SwiftUI

struct MissionView: View {
    @EnvironmentObject var viewModel: MissionViewModel
    @EnvironmentObject var store: StoreManager
    @Environment(\.scenePhase) private var scenePhase
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
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await viewModel.refreshFromDeliveredNotifications()
                        await viewModel.checkNotificationPermission()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let appURL = viewModel.appURL {
                        ShareLink(item: appURL, message: .init(L10n.Mission.shareMessage(appURL.absoluteString))) {
                            Image(icon: .share)
                                .offset(y: -2)
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 5) {
                        Text(L10n.Mission.achievements)
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
                
                ToolbarItem(placement: .topBarTrailing) {
                    settingsMenu
                }
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
            .navigationDestination(isPresented: $viewModel.showAllAgents) {
                AgentsView()
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView()
        case .activeMission(let mission), .completed(let mission), .gaveUp(let mission):
            ActiveMissionView(mission: mission, cardNamespace: cardNamespace)
        case .selection:
            MissionSelectionView(cardNamespace: cardNamespace)
        }
    }
    
    let rows = [GridItem(.fixed(100))]
    
    var settingsMenu: some View {
        Menu {
            Button {
                showSettings = true
            } label: {
                Label(L10n.Menu.settings, systemImage: "gearshape")
            }
            
            if !ProAccess.isPro {
                Button {
                    viewModel.showPaywall = true
                } label: {
                    Label(L10n.Menu.upgradePlan, systemImage: "star")
                }
            }
            
            Divider()
            
            Button {
                showHelp = true
            } label: {
                Label(L10n.Menu.helpAndSupport, systemImage: "questionmark.circle")
            }
        } label: {
            Image(icon: .ellipsis)
        }
    }
}

#Preview {
    struct MissionContainer: View {
        @StateObject var viewModel = MissionViewModel()
        @StateObject var store = StoreManager()
        var body: some View {
            MissionView()
                .environmentObject(viewModel)
                .environmentObject(store)
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
