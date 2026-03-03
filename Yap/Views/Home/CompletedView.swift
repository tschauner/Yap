// CompletedView.swift
// Yap

import SwiftUI

/// Kurze Celebration nachdem ein Goal erledigt wurde.
struct CompletedView: View {
    let goal: Goal
    var onContinue: () -> Void
    
    @State private var confettiScale: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("🎉")
                .font(.system(size: 80))
                .scaleEffect(confettiScale)
            
            VStack(spacing: 8) {
                Text("Done!")
                    .font(.system(size: 32, weight: .bold))
                
                Text("\(goal.title)")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Your \(goal.tone.displayName) is proud. Kinda.")
                    .font(.system(size: 16))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Set another goal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                confettiScale = 1.0
            }
        }
    }
}
