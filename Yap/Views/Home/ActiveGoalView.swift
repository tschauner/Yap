// ActiveGoalView.swift
// Yap

import SwiftUI

/// Wird angezeigt wenn ein aktives Goal existiert.
/// Swipe-to-complete — der einzige Weg die Notifications zu stoppen.
struct ActiveGoalView: View {
    let goal: Goal
    var onDone: () -> Void
    var onExtend: () -> Void
    var onGiveUp: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var showGiveUpConfirm = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Pro badge / status
            HStack {
                Spacer()
                ProBadge()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Spacer()
            
            // Agent emoji
            Text(goal.tone.emoji)
                .font(.system(size: 64))
                .scaleEffect(pulseScale)
            
            // Goal text
            VStack(spacing: 8) {
                Text(goal.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Your \(goal.tone.displayName) is watching.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                
                // Time since created
                Text(goal.createdAt, style: .relative)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
            .padding(.top, 16)
            
            Spacer()
            
            // Slide to complete
            SlideToComplete(onComplete: onDone)
                .padding(.horizontal, 24)
            
            // Extend 24h (only once)
            if !goal.extended {
                Button(action: onExtend) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.2.circlepath")
                        Text("Extend 24h")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            
            // Give up
            Button { showGiveUpConfirm = true } label: {
                Text("Give up")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .confirmationDialog(
            "Really give up?",
            isPresented: $showGiveUpConfirm,
            titleVisibility: .visible
        ) {
            Button("Yes, I give up", role: .destructive, action: onGiveUp)
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Your \(goal.tone.displayName) will not be happy.")
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
    }
}

// MARK: - Slide to Complete

private struct SlideToComplete: View {
    var onComplete: () -> Void
    
    @State private var offsetX: CGFloat = 0
    @State private var completed = false
    
    private let thumbSize: CGFloat = 56
    private let trackHeight: CGFloat = 64
    private let trackPadding: CGFloat = 4
    
    var body: some View {
        GeometryReader { geo in
            let maxOffset = geo.size.width - thumbSize - trackPadding * 2
            let progress = min(offsetX / maxOffset, 1.0)
            
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 20)
                    .fill(.green.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.green.opacity(0.3), lineWidth: 1)
                    )
                
                // Progress fill
                RoundedRectangle(cornerRadius: 20)
                    .fill(.green.gradient.opacity(0.3))
                    .frame(width: offsetX + thumbSize + trackPadding * 2)
                
                // Label
                Text("Slide to complete ✅")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.green.opacity(1 - progress))
                    .frame(maxWidth: .infinity)
                
                // Thumb
                Circle()
                    .fill(.green.gradient)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
                    .offset(x: trackPadding + offsetX)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !completed else { return }
                                offsetX = max(0, min(value.translation.width, maxOffset))
                            }
                            .onEnded { _ in
                                guard !completed else { return }
                                if offsetX > maxOffset * 0.85 {
                                    // Completed!
                                    completed = true
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        offsetX = maxOffset
                                    }
                                    // Haptic
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    // Delay to show completion state
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        onComplete()
                                    }
                                } else {
                                    // Snap back
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        offsetX = 0
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: trackHeight)
    }
}

/// Kleiner Pro-Badge oben rechts.
struct ProBadge: View {
    @ObservedObject private var store = StoreManager.shared
    
    var body: some View {
        if store.isPro {
            Text("PRO")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.gradient)
                .clipShape(Capsule())
        }
    }
}
