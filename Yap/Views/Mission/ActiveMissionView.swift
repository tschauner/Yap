//
//  ActiveMissionView.swift
//  Yap
//
//  Created by Philipp Tschauner on 05.03.26.
//

import SwiftUI
import Combine

struct ActiveMissionView: View {
    @EnvironmentObject var viewModel: MissionViewModel
    let mission: Mission
    var cardNamespace: Namespace.ID
    
    @State var isComplete = false
    @State private var deadlineTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
#if DEBUG
private let isDebug = true
#else
private let isDebug = false
#endif
    
    private var quote: String {
        if mission.isCompleted {
            return mission.agent.completionMessage
        } else if mission.isFailed {
            return mission.agent.giveUpRoast
        } else if let nag = viewModel.currentNagMessage {
            // Once push messages start coming in, show the latest one
            return nag
        } else if let reaction = viewModel.agentReaction {
            // After mission start, show the agent's reaction
            return reaction
        } else {
            // Default: agent pitch
            return mission.agent.pitch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Agent header — always visible
            VStack(spacing: 0) {
                AgentCircle(agent: mission.agent, isSelected: false)
                    .matchedGeometryEffect(id: mission.agent.id, in: cardNamespace)
                    .offset(y: 10)
                    .floatingEffect(enabled: true)
                    .zIndex(1)
                    .overlay(
                        EmojiCelebrationView(
                            isActive: isComplete || mission.isCompleted,
                            emoji: mission.agent.celebrationEmoji
                        )
                    )
                    .shadow(color: mission.agent.accentColor.opacity(0.4), radius: 10, x: -10, y: 10)
                
                AgentPitchCard(agent: mission.agent, pitch: quote)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 35)
            .onTapGesture {
                isComplete.toggle()
            }
            .disabled(!isDebug)
            
            if viewModel.missionReady {
                // Stats + actions fade in when ready
                MissionContentView(mission: mission)
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                // Loading dots
                TypingDotsView()
                    .padding(.bottom, 40)
                    .transition(.opacity)
            }
            
            Spacer()
            
            if viewModel.missionReady && !mission.isFinished {
                Text(L10n.Mission.giveUp)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.red)
                    .button {
                        viewModel.showGiveApAlert = true
                    }
                .padding(.bottom, 25)
                
            } else {
                Spacer()
                    .frame(height: 50)
            }
        }
        .errorFeedback(trigger: viewModel.showGiveApAlert)
        .animation(.easeInOut(duration: 0.4), value: viewModel.missionReady)
        .animation(.spring(), value: mission.isCompleted)
        .onReceive(deadlineTimer) { _ in
            // Check if deadline has passed
            if mission.isExpired {
                viewModel.backToInput()
            }
        }
        .alert(mission.agent.alert, isPresented: $viewModel.showGiveApAlert) {
            Button(L10n.Mission.giveUp, role: .destructive) {
                Task {
                    await viewModel.giveUp(mission)
                }
            }
            
            Button(L10n.Common.cancel, role: .cancel) { }
        }
    }
}

#Preview {
    struct LoadingMissionContainer: View {
        @StateObject var viewModel = MissionViewModel()
        @Namespace var namespace
        var body: some View {
            ActiveMissionView(mission: .dummy(.drill), cardNamespace: namespace)
                .environmentObject(viewModel)
        }
    }
    
    return LoadingMissionContainer()
}

#Preview {
    struct ActiveMissionContainer: View {
        @StateObject var viewModel = MissionViewModel()
        @Namespace var namespace
        var body: some View {
            ActiveMissionView(mission: .active(.drill), cardNamespace: namespace)
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.missionReady = true
                }
        }
    }
    
    return ActiveMissionContainer()
}
