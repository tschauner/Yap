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
    @State private var webURL: WebURL?
    
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
                            .padding(.horizontal)
                            .background(
                                AuroraView()
                                    .frame(width: 280, height: 280)
                            )
//                            .padding(.top, 20)
                        
                        // Comparison table
                        ComparisionTable()
                            .glassEffect(in: .rect(cornerRadius: 16))
//                            .padding(.top, 20)
                            .padding(.horizontal, 24)
                        
                        // Legal
                        termsSection
                            .padding(.vertical, 30)
                        
                        // Bottom spacing for sticky button
                        Spacer()
                            .frame(height: 200)
                    }
                }
                .ignoresSafeArea()
                
                // Sticky bottom purchase area
            }
            .background(Color.black)
            .safeAreaInset(edge: .bottom) {
                purchaseFooter
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Image(icon: .close)
                        .button {
                            dismiss()
                        }
                }
            }
            .sheet(item: $webURL) { item in
                WebView(url: item.url)
            }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 0) {
            Image("grid")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .offset(y: -10)
            
            
            Text(L10n.Paywall.pro)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .padding(.bottom, 16)
            
            Text(L10n.Paywall.headline)
                .font(.system(size: 21, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            // Laurel badge
//            laurelBadge
//                .padding(.top, 20)
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
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(AgentPack.payWall.enumerated()), id: \.offset) { index, agent in
                    AgentSalesPitchCard(agent: agent, showAurora: false)
                        .tag(index)
                }
            }
            .frame(height: 150)
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
            AgentQuoteView(quote: agent.proPitch)
            
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

    // MARK: - Purchase Footer
    
    private var purchaseFooter: some View {
        VStack(spacing: 15) {
            Group {
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let product = store.product {
                    VStack(spacing: 2) {
                        Text(L10n.Paywall.unlockProPrice(product.displayPrice))
                            .font(.system(size: 17, weight: .bold))
                        Text(L10n.Paywall.oneTimePurchase)
                            .font(.system(size: 12, weight: .medium))
                            .opacity(0.8)
                    }
                } else {
                    Text(L10n.Paywall.unlockPro)
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .button {
                Task { await store.purchase() }
            }
            .disabled(store.isLoading || store.product == nil)
            
            // Restore
            Button(L10n.Paywall.restorePurchase) {
                Task { await store.restore() }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .background(
            Color.black
                .ignoresSafeArea(.all, edges: .bottom)
               
        )
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
    struct PayWallContainerView: View {
        @StateObject var viewModel = StoreManager()
        
        var body: some View {
            PaywallView()
                .environmentObject(viewModel)
        }
    }
    
    return PayWallContainerView()
}
