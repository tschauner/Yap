//
//  ContentView.swift
//  Yap
//
//  Created by Philipp Tschauner on 03.03.26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var store = StoreManager.shared
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    var content: some View {
        VStack {
            switch viewModel.phase {
            case .onboarding:
                OnboardingView {
                    viewModel.completeOnboarding()
                }
                .transition(.opacity)
                
            case .activeGoal(let goal):
                ActiveGoalView(
                    goal: goal,
                    onDone: { Task { await viewModel.markGoalDone(goal) } },
                    onExtend: { Task { await viewModel.extendGoal(goal) } },
                    onGiveUp: { Task { await viewModel.giveUpGoal(goal) } }
                )
                .transition(.opacity)
                
            case .input:
                GoalInputView(text: $viewModel.goalText) {
                    viewModel.submitGoalText()
                }
                .overlay(alignment: .topTrailing) {
                    ProBadge().padding(16)
                }
                .transition(.move(edge: .leading))
                
            case .pickAgent:
                AgentPickerView(
                    goalText: viewModel.goalText,
                    onSelect: { viewModel.selectAgent($0) },
                    onBack: { viewModel.backToInput() }
                )
                .transition(.move(edge: .trailing))
                
            case .generating:
                GeneratingView(tone: viewModel.selectedTone ?? .bestFriend)
                    .transition(.opacity)
                
            case .completed(let goal):
                CompletedView(goal: goal) {
                    viewModel.backToInput()
                }
                .transition(.scale.combined(with: .opacity))
                
            case .gaveUp(let goal):
                LoserView(goal: goal) {
                    Task { await viewModel.confirmGaveUp(goal) }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.4), value: viewModel.phase)
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
        .task {
            await viewModel.onAppear()
        }
    }
}

#Preview {
    ContentView()
}
