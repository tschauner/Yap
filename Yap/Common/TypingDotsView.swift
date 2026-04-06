// TypingDotsView.swift
// Yap
//
//  Created by Philipp Tschauner on 17.03.26.
//

import SwiftUI

/// Animated typing indicator (three pulsing dots).
struct TypingDotsView: View {
    @State private var active = 0
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.primary.opacity(active == i ? 0.9 : 0.3))
                    .frame(width: 6, height: 6)
                    .scaleEffect(active == i ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.4), value: active)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                active = (active + 1) % 3
            }
        }
    }
}

#Preview {
    TypingDotsView()
}
