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
    @State private var progressTimer: Timer?
    @State private var completed = false
    
    private let holdDuration: Double = 1.5
    private let tickInterval: Double = 1.0 / 60.0 // 60fps
    
    var body: some View {
        Text(L10n.Mission.holdToComplete)
            .foregroundStyle(Color(.systemBackground))
            .font(.system(size: 16, weight: .semibold))
            .frame(height: 55)
            .padding(.horizontal, 25)
            .background {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Color.primary
                        Color.blue
                            .frame(width: geo.size.width * holdProgress)
                    }
                }
            }
            .overlay {
                GeometryReader { geo in
                    Text(L10n.Mission.holdToComplete)
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: geo.size.width, height: geo.size.height)
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: geo.size.width * holdProgress)
                        }
                }
            }
            .clipShape(Capsule())
            .scaleEffect(isHolding ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHolding)
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
        
        // Drive progress manually via display-link-style timer
        let increment = tickInterval / holdDuration
        progressTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { timer in
            holdProgress = min(holdProgress + increment, 1.0)
            
            if holdProgress >= 1.0 {
                timer.invalidate()
                progressTimer = nil
                completeHold()
            }
        }
        
        // brrrrr — rapid medium buzz ramping up
        var tickCount = 0
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
            let intensity = min(0.6 + Double(tickCount) * 0.016, 1.0)
            medium.impactOccurred(intensity: intensity)
            tickCount += 1
        }
    }
    
    private func completeHold() {
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
    
    private func cancelHold() {
        isHolding = false
        progressTimer?.invalidate()
        progressTimer = nil
        hapticTimer?.invalidate()
        hapticTimer = nil
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }
    }
}

#Preview {
    HoldToCompleteButton {
        print("Done!")
    }
}
