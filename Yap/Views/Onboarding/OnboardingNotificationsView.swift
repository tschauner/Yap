//
//  OnboardingNotificationsView.swift
//  Yap
//
//  Created by Philipp Tschauner on 16.03.26.
//

import SwiftUI

struct OnboardingNotificationsView: View {
    @Binding var selectedAgent: Agent?
    let notificationsEnabled: Bool
    let notificationsDenied: Bool
    
    private var pitchText: String {
        if notificationsEnabled {
            return L10n.Onboarding.notificationsEnabled
        } else if notificationsDenied {
            return L10n.Onboarding.notificationsDenied
        } else {
            return L10n.Onboarding.notificationsDisabled
        }
    }
    
    private var sublineText: String {
        if notificationsEnabled {
            return "\(selectedAgent?.displayName ?? L10n.Onboarding.notificationsAgentFallback) \(L10n.Onboarding.notificationsReady)"
        } else if notificationsDenied {
            return L10n.Onboarding.notificationsDeniedSubline
        } else {
            return L10n.Onboarding.notificationsDisabledSubline
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                VStack(spacing: 0) {
                    AgentCircle(agent: selectedAgent ?? .mom, isSelected: false)
                        .offset(y: 10)
                        .floatingEffect(enabled: true)
                        .zIndex(1)
                        .shadow(color: (selectedAgent ?? .mom).accentColor.opacity(0.4), radius: 10, x: -10, y: 10)
                        .onTapGesture {
                            withAnimation(.snappy(extraBounce: 0.1)) {
                                self.selectedAgent = nil
                            }
                        }
                    
                    AgentPitchCard(agent: selectedAgent ?? .mom, pitch: pitchText)
                        .padding(.horizontal, 40)
                }
            
                Subline(text: sublineText)
                    .padding(.horizontal, 40)
                    .padding(.top, 15)
            }
        }
    }
}

#Preview {
    OnboardingNotificationsView(
        selectedAgent: .constant(.mom),
        notificationsEnabled: false,
        notificationsDenied: false
    )
}
