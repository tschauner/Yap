//
//  OnboardingPaywallView.swift
//  Yap
//
//  Created by Philipp Tschauner on 17.03.26.
//

import SwiftUI
import StoreKit

struct OnboardingPaywallView: View {
    @EnvironmentObject var store: StoreManager
    @AppStorage("completedOnboarding") var completedOnboarding = false
    
    @State private var selectedAgent: Agent = .ex
    @State private var webURL: WebURL?
    
    private let specialAgents = AgentPack.payWall
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                    Text(L10n.Paywall.pro)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .padding(.top, 70)
                    
                    Text(L10n.Paywall.headline)
                        .font(.system(size: 21, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    // Quote
                    VStack(spacing: 0) {
                        AgentSalesPitchCard(agent: selectedAgent)
                            .frame(height: 140)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 30)
                        
                        // Agent ScrollView
                        agentScroll
                            .padding(.bottom, 40)
                        
                        // Features
                        ComparisionTable()
                            .glassEffect(in: .rect(cornerRadius: 16))
                            .padding(.horizontal, 30)
                        
                        // Legal
                        termsSection
                            .padding(.vertical, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .scrollIndicators(.hidden)
        }
        .sheet(item: $webURL) { item in
            WebView(url: item.url)
        }
        .hapticFeedback(trigger: selectedAgent)
        .onChange(of: store.isPro) { _, isPro in
            if isPro { completedOnboarding = true }
        }
        .task { await store.loadProducts() }
    }
    
    // MARK: - Agent Scroll
    
    /// Static scale based on position — dome shape, doesn't change on selection.
    private static let positionScales: [CGFloat] = [1.0, 1.1, 1.2, 1.2, 1.1, 1.0]
    
    func offset(for index: Int) -> CGFloat {
        switch index {
        case 0:
            10
        case specialAgents.count - 1:
            -10
        default: 0
        }
    }
    
    private var agentScroll: some View {
        HStack(spacing: 5) {
            ForEach(Array(specialAgents.enumerated()), id: \.element) { index, agent in
                Circle()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(agent.accentColor.gradient)
                    .overlay(
                        Text(agent.emoji)
                            .font(.system(size: 40, weight: .semibold))
                    )
//                    .offset(x: offset(for: index))
                    .opacity(agent == selectedAgent ? 1.0 : 0.4)
                    .animation(.easeInOut(duration: 0.2), value: selectedAgent)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedAgent = agent
                        }
                    }
            }
        }
        .padding(.horizontal, -10)
    }
    
    // MARK: - Features
    
    private var features: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureRow(L10n.Paywall.featureSpecialAgents)
            featureRow(L10n.Paywall.featureAgentMemory)
            featureRow(L10n.Paywall.featureUnlimitedMissions)
        }
    }
    
    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(icon: .checkmark)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.yellow)
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 10)
    }
    
    private var termsSection: some View {
        HStack(spacing: 16) {
            Text(L10n.Legal.privacyPolicy)
                .font(.caption)
                .button {
                    webURL = .init(url: URL(string: "https://yap.fail/privacy")!)
                }
            Text("·")
            Text(L10n.Legal.termsOfUse)
                .font(.caption)
                .button {
                    webURL = .init(url: URL(string: "https://yap.fail/terms")!)
                }
        }
        .font(.system(size: 12))
        .foregroundStyle(.tertiary)
    }
}

#Preview {
    OnboardingPaywallView()
        .environmentObject(StoreManager())
}
