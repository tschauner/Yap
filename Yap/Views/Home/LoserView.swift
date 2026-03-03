// LoserView.swift
// Yap

import SwiftUI

/// Shown when the user gives up on a goal.
/// Stats + persona roast = screenshot-worthy shame.
struct LoserView: View {
    let goal: Goal
    var onTryAgain: () -> Void
    
    @State private var appeared = false
    
    private var durationText: String {
        let minutes = Int(goal.duration / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)min"
        }
        return "\(mins)min"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Big emoji
            Text(goal.tone.emoji)
                .font(.system(size: 80))
                .scaleEffect(appeared ? 1 : 0.3)
                .opacity(appeared ? 1 : 0)
            
            // Roast
            Text(goal.tone.giveUpRoast)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            
            // Stats card
            VStack(spacing: 16) {
                StatRow(icon: "clock", label: "Lasted", value: durationText)
                StatRow(icon: "bell.slash", label: "Messages ignored", value: "\(goal.estimatedIgnoredMessages)")
                StatRow(icon: "flame", label: "Peak level", value: goal.peakEscalation.displayName)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
            
            // Goal text
            Text("\"\(goal.title)\"")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
                .padding(.top, 16)
                .opacity(appeared ? 1 : 0)
            
            Spacer()
            
            // Try again
            Button(action: onTryAgain) {
                Text("Try again")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Stat Row

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
        }
    }
}

// MARK: - Escalation Level Display Name

extension EscalationLevel {
    var displayName: String {
        switch self {
        case .gentle: "Gentle"
        case .nudge: "Nudge"
        case .push: "Push"
        case .urgent: "Urgent"
        case .meltdown: "Meltdown"
        }
    }
}
