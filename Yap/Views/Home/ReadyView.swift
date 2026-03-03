// ReadyView.swift
// Yap

import SwiftUI

/// Bestätigung: Agent ist bereit, Copy wurde generiert.
struct ReadyView: View {
    let goal: Goal
    var onNewGoal: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text(goal.tone.emoji)
                .font(.system(size: 72))
            
            VStack(spacing: 8) {
                Text("You're all set")
                    .font(.system(size: 28, weight: .bold))
                
                Text("\(goal.title)")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Your \(goal.tone.displayName) won't let you forget.")
                    .font(.system(size: 16))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Button(action: onNewGoal) {
                Text("Set another goal")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }
}
