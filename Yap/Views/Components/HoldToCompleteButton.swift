//
//  HoldToCompleteButton.swift
//  Yap
//
//  Created by Philipp Tschauner on 10.03.26.
//

import SwiftUI

struct HoldToCompleteButton: View {
    let onComplete: () -> Void
    
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var hapticTimer: Timer?
    @State private var completed = false
    
    private let holdDuration: Double = 2.0
    
    var body: some View {
        Text("Hold to complete")
            .foregroundStyle(Color(.systemBackground))
            .font(.system(size: 16, weight: .semibold))
            .frame(height: 35)
            .padding(.horizontal, 18)
            .background(Color.primary)
            .clipShape(Capsule())
            .scaleEffect(isHolding ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHolding)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isHolding, !completed else { return }
                        isHolding = true
                        startHoldSequence()
                    }
                    .onEnded { _ in
                        if !completed {
                            cancelHold()
                        }
                    }
            )
    }
    
    private func startHoldSequence() {
        // Instant first hit so it feels immediate
        let medium = UIImpactFeedbackGenerator(style: .medium)
        medium.impactOccurred(intensity: 0.6)
        
        // brrrrr — rapid medium buzz ramping up
        var tickCount = 0
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
            let intensity = min(0.6 + Double(tickCount) * 0.012, 1.0)
            medium.impactOccurred(intensity: intensity)
            tickCount += 1
        }
        
        // After hold duration → BLOPP
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
            guard isHolding else { return }
            completed = true
            hapticTimer?.invalidate()
            hapticTimer = nil
            
            // Short silence then one fat blopp
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                let heavy = UIImpactFeedbackGenerator(style: .heavy)
                heavy.impactOccurred(intensity: 1.0)
            }
            
            isHolding = false
            onComplete()
        }
    }
    
    private func cancelHold() {
        isHolding = false
        hapticTimer?.invalidate()
        hapticTimer = nil
    }
}

#Preview {
    HoldToCompleteButton {
        print("Done!")
    }
}
