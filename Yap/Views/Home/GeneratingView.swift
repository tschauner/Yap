// GeneratingView.swift
// Yap

import SwiftUI

/// Ladescreen während GPT die Copy generiert.
struct GeneratingView: View {
    let tone: NagTone
    
    @State private var dots = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text(tone.emoji)
                .font(.system(size: 72))
            
            Text("Your \(tone.displayName) is getting ready\(dots)")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
            
            ProgressView()
                .tint(.primary)
            
            Spacer()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation {
                    dots = dots.count >= 3 ? "" : dots + "."
                }
            }
        }
    }
}
