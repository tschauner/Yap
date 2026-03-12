// PaywallView.swift
// Yap

import SwiftUI
import StoreKit
import Combine

struct PaywallView: View {
    @EnvironmentObject var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentPage: Int = 0
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        header
                        
                        // Agent quotes carousel
                        agentQuotes
                            .padding(.top, 32)
                        
                        // Comparison table
                        comparisonTable
                            .padding(.top, 40)
                            .padding(.horizontal, 24)
                        
                        // Bottom spacing for sticky button
                        Spacer()
                            .frame(height: 160)
                    }
                }
                
                // Sticky bottom purchase area
            }
            .background(.quinary)
            .safeAreaInset(edge: .bottom) {
                purchaseFooter
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Image(icon: .close)
                }
            }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 16) {
            Text("PRO")
                .font(.system(size: 48, weight: .black, design: .rounded))
            
            Text("Unlock your full motivation squad.")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
            
            // Laurel badge
            laurelBadge
                .padding(.top, 20)
        }
    }
    
    private var laurelBadge: some View {
        HStack(spacing: 15) {
            Image(icon: .laurelLeading)
                .font(.system(size: 60))
            Text("Voted most annoying app\nby our users")
                .font(.system(size: 21, weight: .semibold))
                .multilineTextAlignment(.center)
                .tracking(0.3)
            Image(icon: .laurelTrailing)
                .font(.system(size: 60))
        }
        .frame(maxWidth: .infinity)
//        .padding(.horizontal, 20)
    }
    
    // MARK: - Agent Quotes Carousel
    
    private var agentQuotes: some View {
        VStack(spacing: 16) {
            TabView(selection: $currentPage) {
                ForEach(Array(Agent.standard.enumerated()), id: \.offset) { index, agent in
                    quoteCard(agent)
                        .tag(index)
                }
            }
            .frame(height: 200)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPage = (currentPage + 1) % Agent.allCases.count
                }
            }
            
            HStack {
                ForEach(Array(Agent.standard.enumerated()), id: \.offset) { index, agent in
                    Circle()
                        .frame(width: 7)
                        .foregroundStyle(currentPage == index ? .white : .secondary)
                }
            }
        }
    }
    
    private func quoteCard(_ agent: Agent) -> some View {
        VStack(spacing: 16) {
            AgentQuoteView(quote: agent.salesPitch)
            
            VStack(spacing: 6) {
                AgentCircle(agent: agent)
                Text(agent.displayName)
                    .font(.caption)
            }
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .glassEffect(in: .rect(cornerRadius: 20))
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
    
    // MARK: - Comparison Table
    
    private var comparisonTable: some View {
        VStack(spacing: 0) {
            // Table header
            HStack {
                Spacer()
                Text("Free")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 56)
                Text("Pro")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 56)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            // Rows
            comparisonRow("Agent", free: "Mom", pro: "All 6")
            comparisonRow("Missions / day", free: "1", pro: "∞")
            comparisonRow("AI-powered messages", free: true, pro: true)
            comparisonRow("Agent Leaderboard", free: true, pro: true)
            comparisonRow("Custom quiet hours", free: true, pro: true)
            comparisonRow("Extend deadline", free: false, pro: true, showDivider: false)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark
                      ? Color(.systemGray6)
                      : Color.white)
        )
    }
    
    private func comparisonRow(_ label: String, free: Bool, pro: Bool, showDivider: Bool = true) -> some View {
        comparisonRowContent(label, content: {
            checkOrDash(free, highlighted: false)
                .frame(width: 56)
            checkOrDash(pro, highlighted: true)
                .frame(width: 56)
        }, showDivider: showDivider)
    }
    
    private func comparisonRow(_ label: String, free: String, pro: String, showDivider: Bool = true) -> some View {
        comparisonRowContent(label, content: {
            Text(free)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 56)
            Text(pro)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 56)
                .frame(width: 56)
        }, showDivider: showDivider)
    }
    
    private func comparisonRowContent<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content,
        showDivider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                Spacer()
                content()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, showDivider ? 14 : 0)
            
            if showDivider {
                Divider()
                    .padding(.horizontal, 16)
            }
        }
    }
    
    @ViewBuilder
    private func checkOrDash(_ value: Bool, highlighted: Bool) -> some View {
        if value {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(highlighted ? Color.primary : .secondary)
        } else {
            Text("–")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.quaternary)
        }
    }
    
    // MARK: - Purchase Footer
    
    private var purchaseFooter: some View {
        VStack(spacing: 10) {
            Group {
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let product = store.product {
                    VStack(spacing: 2) {
                        Text("Unlock Pro — \(product.displayPrice)")
                            .font(.system(size: 17, weight: .bold))
                        Text("One-time purchase")
                            .font(.system(size: 12, weight: .medium))
                            .opacity(0.8)
                    }
                } else {
                    Text("Unlock Pro")
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .button {
                Task { await store.purchase() }
            }
            .disabled(store.isLoading || store.product == nil)
            
            // Restore
            Button("Restore purchase") {
                Task { await store.restore() }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(.all, edges: .bottom)
        )
    }
}

#Preview {
    struct PayWallContainerView: View {
        @StateObject var viewModel = StoreManager()
        
        var body: some View {
            PaywallView()
                .environmentObject(viewModel)
        }
    }
    
    return PayWallContainerView()
}
