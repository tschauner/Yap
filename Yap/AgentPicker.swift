//
//  AgentPicker.swift
//  Yap
//
//  Created by Philipp Tschauner on 05.03.26.
//

import SwiftUI

enum PickerState: Equatable {
    case selection
    case setup(Agent)
    
    var isLoading: Bool {
        switch self {
        case .setup:
            return true
        default:
            return false
        }
    }
}

struct AgentPicker: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: HomeViewModel
    
    let mission: MissionItem
    
    init(mission: MissionItem, pickerState: PickerState = .selection) {
        self.mission = mission
        self._pickerState = .init(wrappedValue: pickerState)
    }
    
    @State private var selectedAgent: Agent?
    @State private var pickerState: PickerState = .selection
    
    var body: some View {
        NavigationStack {
            VStack {
                switch pickerState {
                case .selection:
                    AgentList()
                case .setup(let agent):
                    progressView(for: agent)
                }
            }
            .padding(.horizontal)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Image(icon: .close)
                        .button {
                            dismiss()
                        }
                }
                
                if viewModel.selectedAgent != nil, !pickerState.isLoading {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func progressView(for agent: Agent) -> some View {
        MissionLoadingBar(text: "Deploying \(agent.displayName)...")
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.horizontal)
    }
}

// MARK: - Mission Loading Bar

struct MissionLoadingBar: View {
    let text: String
    
    @State private var phase: CGFloat = 0
    
    private let barHeight: CGFloat = 48
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
            
            // Animated diagonal stripes
            DiagonalStripesPattern(phase: phase)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Text overlay
            Text(text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(height: barHeight)
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

struct DiagonalStripesPattern: View {
    let phase: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let stripeWidth: CGFloat = 24
            let stripeSpacing: CGFloat = 24
            let totalWidth = stripeWidth + stripeSpacing
            let offset = phase * totalWidth
            
            // Draw diagonal stripes
            var x: CGFloat = -size.height - totalWidth + offset
            while x < size.width + size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height + stripeWidth, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                path.closeSubpath()
                
                context.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.12)
                        ]),
                        startPoint: CGPoint(x: x, y: size.height),
                        endPoint: CGPoint(x: x + size.height, y: 0)
                    )
                )
                x += totalWidth
            }
        }
    }
}


#Preview {
    AgentPicker(mission: .init(title: "Wäsche waschen"))
    AgentPicker(mission: .init(title: "Wäsche waschen"), pickerState: .setup(.boss))
}

#Preview("Loading Bar") {
    MissionLoadingBar(text: "Deploying Drill Sergeant...")
        .padding()
}
