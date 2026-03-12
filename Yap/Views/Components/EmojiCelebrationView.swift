//
//  EmojiCelebrationView.swift
//  Yap
//
//  Created by Philipp Tschauner on 10.03.26.
//

import SwiftUI

struct EmojiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let spawnTime: Date
    let duration: Double        // how long it lives (2–3s)
    let size: CGFloat
    let swayAmplitude: CGFloat  // how far it sways left/right
    let swayFrequency: Double   // how fast it sways
    let startX: CGFloat         // initial random x offset
    let startPhase: Double      // random phase for sway
}

struct EmojiCelebrationView: View {
    let isActive: Bool
    let emoji: String
    
    @State private var particles: [EmojiParticle] = []
    @State private var spawnTimer: Timer?
    @State private var spawnCount = 0
    private let totalEmojis = 14
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date
            ZStack {
                ForEach(particles) { particle in
                    let elapsed = now.timeIntervalSince(particle.spawnTime)
                    let progress = min(elapsed / particle.duration, 1.0) // 0→1
                    
                    let swayX = particle.swayAmplitude * sin(elapsed * particle.swayFrequency + particle.startPhase)
                    let yTravel: CGFloat = -280 * progress
                    
                    // Fade: full opacity first 60%, then fade out
                    let opacity = progress < 0.6 ? 1.0 : max(0, 1.0 - (progress - 0.6) / 0.4)
                    // Scale: pop in then shrink slightly at end
                    let scale = progress < 0.1 ? progress / 0.1 : (progress > 0.7 ? max(0.4, 1.0 - (progress - 0.7)) : 1.0)
                    
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .scaleEffect(scale)
                        .offset(x: particle.startX + swayX, y: yTravel)
                        .opacity(opacity)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startSpawning()
            }
        }
        .onAppear {
            if isActive {
                startSpawning()
            }
        }
        .onDisappear {
            spawnTimer?.invalidate()
        }
    }
    
    private func startSpawning() {
        spawnCount = 0
        particles = []
        
        // Spawn emojis one by one, every ~0.07s
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { timer in
            guard spawnCount < totalEmojis else {
                timer.invalidate()
                // Clean up after last emoji finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    particles = []
                }
                return
            }
            
            let particle = EmojiParticle(
                emoji: emoji,
                spawnTime: Date(),
                duration: Double.random(in: 0.5...0.9),
                size: CGFloat.random(in: 20...34),
                swayAmplitude: CGFloat.random(in: 10...25),
                swayFrequency: Double.random(in: 2...4),
                startX: CGFloat.random(in: -40...40),
                startPhase: Double.random(in: 0...(.pi * 2))
            )
            particles.append(particle)
            spawnCount += 1
        }
    }
}

#Preview {
    EmojiCelebrationView(isActive: true, emoji: "🔥")
}
