// AgentPickerView.swift
// Yap

import SwiftUI

/// Agent-Auswahl: jeder Tone als Karte mit Emoji + Name + Beschreibung.
struct AgentPickerView: View {
    let goalText: String
    var onSelect: (NagTone) -> Void
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Pick your agent")
                    .font(.system(size: 28, weight: .bold))
                
                Text("\(goalText)")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.top, 40)
            
            // Agent Cards
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(NagTone.allCases) { tone in
                        AgentCard(tone: tone) {
                            onSelect(tone)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Back
            Button(action: onBack) {
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Agent Card

private struct AgentCard: View {
    let tone: NagTone
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(tone.emoji)
                    .font(.system(size: 36))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tone.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(tone.description)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
