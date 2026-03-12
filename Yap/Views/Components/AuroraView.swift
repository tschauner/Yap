//
//  AuroraView.swift
//  Yap
//
//  Created by Philipp Tschauner on 10.03.26.
//

import SwiftUI

struct AuroraView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                let cx = size.width / 2
                let cy = size.height / 2
                
                // 3 blobs rotating at different speeds
                let blobs: [(Color, Double, Double, Double)] = [
                    (.purple, 0.08, 0.6, 0),
                    (.blue, 0.06, 0.5, 2.1),
                    (.pink, 0.1, 0.45, 4.2),
                ]
                
                for (color, speed, radius, offset) in blobs {
                    let angle = now * speed + offset
                    let r = radius * min(size.width, size.height)
                    let x = cx + cos(angle) * r * 0.4
                    let y = cy + sin(angle) * r * 0.3
                    
                    let blobSize = r * 1.8
                    let rect = CGRect(
                        x: x - blobSize / 2,
                        y: y - blobSize / 2,
                        width: blobSize,
                        height: blobSize
                    )
                    
                    let gradient = Gradient(colors: [
                        color.opacity(0.4),
                        color.opacity(0.15),
                        color.opacity(0)
                    ])
                    
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            gradient,
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: blobSize / 2
                        )
                    )
                }
            }
            .blur(radius: 50)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AuroraView()
            .frame(width: 300, height: 300)
    }
}
