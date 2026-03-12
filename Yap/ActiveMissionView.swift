//
//  ActiveMissionView.swift
//  Yap
//
//  Created by Philipp Tschauner on 05.03.26.
//

import SwiftUI

struct ActiveMissionView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    let mission: Mission
    var cardNamespace: Namespace.ID
    
    @State var isComplete = false
    
#if DEBUG
private let isDebug = true
#else
private let isDebug = false
#endif
    
    private var quote: String {
        if mission.isCompleted {
            return mission.agent.completionMessage
        } else {
            return viewModel.currentNagMessage ?? mission.agent.pitch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Agent header — always visible
            AgentCard(
                agent: mission.agent,
                isSelected: false,
                isFloading: false,
                cardSize: .big
            )
            .matchedGeometryEffect(id: mission.agent.id, in: cardNamespace)
            .overlay {
                EmojiCelebrationView(
                    isActive: isComplete || mission.isCompleted,
                    emoji: mission.agent.celebrationEmoji
                )
            }
            .padding(.bottom, 10)
            .onTapGesture {
                viewModel.missionReady.toggle()
            }
            .disabled(!isDebug)
            
            AgentQuoteView(quote: quote)
                .padding(.horizontal, 50)
                .padding(.bottom, 40)
                .animation(.easeInOut, value: viewModel.currentNagMessage)
                .task {
                    await viewModel.loadNextNagMessage(for: mission.id)
                }
                .onTapGesture {
                    isComplete.toggle()
                }
                .disabled(!isDebug)
            
            if viewModel.missionReady {
                // Stats + actions fade in when ready
                missionContent
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                // Loading dots
                TypingDotsView()
                    .padding(.bottom, 40)
                    .transition(.opacity)
            }
            
            Spacer()
            
            if viewModel.missionReady && !mission.isCompleted {
                Text("Give up")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.red)
                    .button {
                        viewModel.showGiveApAlert = true
                    }
            } else {
                Spacer()
                    .frame(height: 50)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.missionReady)
        .animation(.spring(), value: mission.isCompleted)
        .alert(mission.agent.alert, isPresented: $viewModel.showGiveApAlert) {
            Button("Give up", role: .destructive) {
                Task {
                    await viewModel.giveUp(mission)
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // MARK: - Mission Content (fades in when ready)
    
    private var missionContent: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(icon: .bell)
                        .font(.system(size: 13, weight: .medium))
//                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("\(mission.notificationsScheduled) messages scheduled")
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                HStack {
                    Image(icon: .eye)
                        .font(.system(size: 13, weight: .medium))
//                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("\(mission.estimatedIgnoredMessages) messages ignored")
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                HStack {
                    Image(icon: .clock)
                        .font(.system(size: 13, weight: .medium))
//                        .foregroundStyle(.primary)
                        .frame(width: 20)
                    if mission.isCompleted {
                        Text(mission.durationFormatted)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(mission.createdAt, style: .relative)
                           .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Spacer()
                    if mission.isCompleted {
                        Text("Set another mission")
                            .foregroundStyle(Color(.systemBackground))
                            .font(.system(size: 16, weight: .semibold))
                            .frame(height: 35)
                            .padding(.horizontal)
                            .background(Color.primary)
                            .clipShape(Capsule())
                            .button {
                                viewModel.backToInput()
                            }
                    } else {
                        HoldToCompleteButton {
                            Task {
                                await viewModel.markMissionDone(mission)
                            }
                        }
                    }
                    
                    Spacer()

                }
                .padding(.top)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottomTrailing) {
                ZStack {
                    if viewModel.missionIsCompleting {
                        ProgressView()
                            .padding(.bottom, 5)
                    }
                }
            }
            .padding(20)
            .background(.thinMaterial)
            .cornerRadius(20)
            .glassEffect(in: .rect(cornerRadius: 20))
            .padding(.horizontal, 20)
            
            if !mission.isCompleted {
                Text("Extend +24 h")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 15, weight: .medium))
                    .button {
                        Task {
                            await viewModel.extend(mission)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(height: 60)
            }
        }
    }
}

#Preview {
    struct ActiveMissionContainer: View {
        @StateObject var viewModel = HomeViewModel()
        @Namespace var namespace
        var body: some View {
            ActiveMissionView(mission: .dummy(.drill), cardNamespace: namespace)
                .environmentObject(viewModel)
        }
    }
    
    return ActiveMissionContainer()
}
