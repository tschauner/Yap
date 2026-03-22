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
                    
                    AgentPitchCard(agent: selectedAgent ?? .mom, pitch: notificationsEnabled ? L10n.Onboarding.notificationsEnabled : L10n.Onboarding.notificationsDisabled)
                        .padding(.horizontal, 40)
                }
            
                Subline(text: notificationsEnabled ? "\(selectedAgent?.displayName ?? L10n.Onboarding.notificationsAgentFallback) \(L10n.Onboarding.notificationsReady)" : L10n.Onboarding.notificationsDisabledSubline)
                    .padding(.horizontal, .horizontal)
                    .padding(.top, 15)
            }
            
        }
    }
}

#Preview {
    OnboardingNotificationsView(
        selectedAgent: .constant(.mom),
        notificationsEnabled: false
    )
}
