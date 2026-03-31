//
//  MissionContentView.swift
//  Yap
//
//  Created by Philipp Tschauner on 18.03.26.
//

import SwiftUI

struct MissionContentView: View {
    @EnvironmentObject var viewModel: MissionViewModel
    let mission: Mission
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(icon: .flag)
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 20)
                    Text(mission.title)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
                
                Divider()
                
                HStack {
                    Image(icon: .eyeSlash)
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 20)
                    Text(L10n.Mission.messagesIgnored(mission.estimatedIgnoredMessages))
                        .foregroundStyle(mission.isFailed || mission.isGivenUp ? .red : .secondary)
                }
                
                Divider()
                
                HStack {
                    Image(icon: .clock)
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 20)
                    if mission.isFinished {
                        Text(mission.durationFormatted)
                            .foregroundStyle(mission.isFailed || mission.isGivenUp ? .red : .secondary)
                    } else {
                        HStack(spacing: 5) {
                            Text(mission.deadline, style: .relative)
                                .foregroundStyle(.secondary)
                            Text(L10n.Mission.left)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if !mission.extended {
                            Image(icon: .extend)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.vertical, 5)
                                .padding(.horizontal, 15)
                                .background(.quinary)
                                .clipShape(Capsule())
                                .button {
                                    viewModel.showExtendAlert = true
                                }
                        }
                    }
                }
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
            .cornerRadius(40)
            .glassEffect(in: .rect(cornerRadius: 20))
            .padding(.bottom, 20)
            
            if mission.isFinished {
                Text(L10n.Mission.setAnother)
                    .foregroundStyle(Color(.systemBackground))
                    .font(.system(size: 16, weight: .semibold))
                    .frame(height: 55)
                    .padding(.horizontal, 25)
                    .background(Color.primary)
                    .clipShape(Capsule())
                    .button {
                        viewModel.backToInput()
                    }
            } else {
                HoldToCompleteButton {
                    Task {
                        SoundEngine.play(.success(mission.agent))
                        await viewModel.markMissionDone(mission)
                    }
                }
            }
        }
    }
}

#Preview {
    struct MissionContainer: View {
        @StateObject var viewModel = MissionViewModel()
        
        var body: some View {
            MissionContentView(mission: .active(.mom))
                .environmentObject(viewModel)
        }
    }
    
    return MissionContainer()
}
