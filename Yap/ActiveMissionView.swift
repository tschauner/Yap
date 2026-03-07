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
    @State var isCompleting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: 10) {
                Text(mission.agent.emoji)
                    .font(.system(size: 24, weight: .bold))
                Text(mission.agent.displayName)
                    .font(.system(size: 20, weight: .bold))
            }
            .padding(.bottom, 10)
            
            Text(mission.tagline)
                .font(.system(size: 17, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
                .padding(.horizontal, 50)
  
            VStack(alignment: .leading) {
                Text(mission.title)
                    .strikethrough(mission.isCompleted)
                
                Divider()
                
                HStack {
                    Image(icon: .bell)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("\(mission.notificationsScheduled) messages scheduled")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Image(icon: .eye)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("\(mission.estimatedIgnoredMessages) messages ignored")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Image(icon: .clock)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    if mission.isCompleted {
                        Text(mission.durationFormatted)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(mission.createdAt, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .border(.primary)
            
            if !mission.isCompleted {
                HStack {
                    Text("Mission completed")
                        .foregroundStyle(.white)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(height: 50)
                    if isCompleting {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .button {
                    Task {
                        isCompleting = true
                        await viewModel.markMissionDone(mission)
                    }
                }
                .background(Color.primary)
                .cornerRadius(5)
                .padding(.top, 20)
                
                Text("Extend +24 h")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 15, weight: .medium))
                    .button {
                        Task {
                            await viewModel.extend(mission)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
            } else {
                Text("Set another mission")
                    .foregroundStyle(.white)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .button {
                        viewModel.backToInput()
                    }
                    .background(Color.primary)
                    .cornerRadius(5)
                    .padding(.top, 20)
                
                if let first = viewModel.queuedMissions.first {
                    Text("Start \(first.title)")
                        .foregroundStyle(.white)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .button {
                            viewModel.selectedMission = first
                        }
                        .background(.tertiary)
                        .cornerRadius(5)
                        .padding(.top, 10)
                }
            }
            
            Spacer()
            
            
            if !mission.isCompleted {
                Text("Give up")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.red)
                    .button {
                        viewModel.showGiveApAlert = true
                    }
            }
        }
        .padding(.horizontal)
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
}

#Preview {
    struct ActiveMissionContainer: View {
        @StateObject var viewModel = HomeViewModel()
        var body: some View {
            ActiveMissionView(mission: .dummy(.drill))
                .environmentObject(viewModel)
        }
    }
    
    return ActiveMissionContainer()
}
