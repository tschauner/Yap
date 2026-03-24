// OnboardingView.swift
// Yap

import SwiftUI
import StoreKit

struct OnboardingView: View {
    
    enum Page: CaseIterable {
        case welcome
        case agents
        case deadline
        case notifiation
        case paywall
        
        var canBeSkipped: Bool {
            switch self {
            case .paywall:
                return true
            default:
                return false
            }
        }
    }
    
    private let totalPages = 5
    @Namespace var namespace
    @AppStorage("completedOnboarding") var completedOnboarding = false
    @EnvironmentObject var store: StoreManager
    
    @State private var currentPage: Page = .welcome
    @State private var selectedAgent: Agent?
    @State private var notificationsEnabled = false
    
    private var buttonDisabled: Bool {
        switch currentPage {
        case .agents:
            return selectedAgent == nil
        default: return false
        }
    }
    
    private var buttonTitle: String {
        switch currentPage {
        case .notifiation:
            return notificationsEnabled ? L10n.Onboarding.letsGo : L10n.Onboarding.allowNotifications
        default: return L10n.Onboarding.next
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            TabView(selection: $currentPage) {
                OnboardingStartView()
                    .tag(Page.welcome)
                
                OnboardingAgentsView(
                    selectedAgent: $selectedAgent,
                    namespace: namespace
                )
                .tag(Page.agents)
                
                DeadlineOnboardingView()
                    .tag(Page.deadline)
                
                OnboardingNotificationsView(
                    selectedAgent: $selectedAgent,
                    notificationsEnabled: notificationsEnabled
                )
                .tag(Page.notifiation)
                
                OnboardingPaywallView()
                    .environmentObject(store)
                    .tag(Page.paywall)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            .ignoresSafeArea(edges: .top)
            .hapticFeedback(trigger: selectedAgent)
            .hapticFeedback(trigger: currentPage)
            
            // Bottom
            .safeAreaInset(edge: .bottom) {
                VStack {
                    if currentPage == .paywall {
                        // Paywall CTA
                        VStack(spacing: 15) {
                            paywallButton
                            
                            Button(L10n.Onboarding.maybeLater) {
                                completedOnboarding = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(height: 60)
                            .padding(.horizontal, 40)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .button {
                                handleNext()
                            }
                            .disabled(buttonDisabled)
                            .opacity(buttonDisabled ? 0 : 1)
                    }
                }
                .frame(height: 90, alignment: .top)
                .padding(.top, 5)
            }
        }
    }
    
    private func handleNext() {
        switch currentPage {
        case .welcome:
            currentPage = .agents
        case .agents:
            currentPage = .deadline
        case .deadline:
            currentPage = .notifiation
        case .notifiation:
            if notificationsEnabled {
                currentPage = .paywall
            } else {
                Task {
                    await NagService.shared.requestPermission()
                    await MainActor.run {
                        withAnimation { notificationsEnabled = true }
                    }
                }
            }
        case .paywall:
            completedOnboarding = true
        }
    }
    
    // MARK: - Paywall Button
    
    private var paywallButton: some View {
        Group {
            if store.isLoading {
                ProgressView()
                    .tint(.white)
            } else if let product = store.product {
                VStack(spacing: 2) {
                    Text(L10n.Onboarding.goProPrice(product.displayPrice))
                        .font(.system(size: 17, weight: .bold))
                    Text(L10n.Onboarding.lifetimeSubline)
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.8)
                }
            } else {
                Text(L10n.Onboarding.goPro)
                    .font(.system(size: 17, weight: .bold))
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 24)
        .button {
            Task { await store.purchase() }
        }
        .disabled(store.isLoading || store.product == nil)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(StoreManager())
}
