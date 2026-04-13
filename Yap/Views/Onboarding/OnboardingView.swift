// OnboardingView.swift
// Yap

import SwiftUI
import StoreKit

struct OnboardingView: View {
    
    enum Page: CaseIterable {
        case welcome
        case agents
        case deadline
        case name
        case notifiation
        case paywall
        
        static var pages: [Self] {
            [.welcome, .agents, .deadline, .name, .notifiation]
        }
        
        var canBeSkipped: Bool {
            switch self {
            case .name, .paywall:
                return true
            default:
                return false
            }
        }
        
        var showPageIndicator: Bool {
            switch self {
            case .welcome, .paywall:
                return false
            default:
                return true
            }
        }
    }
    
    private let totalPages = 5
    @Namespace var namespace
    @AppStorage("completedOnboarding") var completedOnboarding = false
    @AppStorage("user_display_name") private var userName: String = ""
    @AppStorage("isPro") var isPro = false
    @EnvironmentObject var store: StoreManager
    
    @State private var currentPage: Page = .welcome
    @State private var selectedAgent: Agent?
    @State private var notificationsEnabled = false
    @State private var notificationsDenied = false
    @State private var isFocused = false
    
    private var buttonDisabled: Bool {
        switch currentPage {
        case .agents:
            return selectedAgent == nil
        default: return false
        }
    }
    
    private var buttonTitle: String {
        switch currentPage {
        case .name:
            return L10n.Onboarding.next
        case .notifiation:
            if notificationsEnabled {
                return L10n.Onboarding.letsGo
            } else if notificationsDenied {
                return L10n.Onboarding.continueAnyway
            } else {
                return L10n.Onboarding.allowNotifications
            }
        default: return L10n.Onboarding.next
        }
    }
    
    var body: some View {
        NavigationStack {
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
                    
                    OnboardingNameView(focused: $isFocused)
                        .tag(Page.name)
                    
                    OnboardingNotificationsView(
                        selectedAgent: $selectedAgent,
                        notificationsEnabled: notificationsEnabled,
                        notificationsDenied: notificationsDenied
                    )
                    .tag(Page.notifiation)
                    
                    OnboardingPaywallView()
                        .environmentObject(store)
                        .tag(Page.paywall)
                    
                    
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .scrollContentBackground(.hidden)
                .hapticFeedback(trigger: selectedAgent)
                .hapticFeedback(trigger: currentPage)
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                .background(alignment: .top) {
                    Image("grid")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .transition(.opacity)
                        .ignoresSafeArea()
                        .opacity(currentPage == .welcome ? 1 : 0)
                        .transition(.opacity)
                }
                
                // Bottom
                .overlay(alignment: .top) {
                    Group {
                        if currentPage.showPageIndicator {
                            HStack(spacing: 4) {
                                ForEach(Page.pages, id: \.self) { page in
                                    RoundedRectangle(cornerRadius: 2)
                                        .frame(height: 3)
                                        .frame(maxWidth: .infinity)
                                        .opacity(page == currentPage ? 1 : 0.1)
                                }
                            }
                            .padding(.horizontal, .horizontal)
                            .padding(.top, 30)
                        } else {
                            Spacer()
                                .frame(height: 3)
                        }
                    }
                    .frame(width: 300)
                }
                .safeAreaInset(edge: .bottom) {
                    VStack {
                        if isFocused {
                            userNameButton
                        } else if currentPage == .paywall {
                            // Paywall CTA
                            payWallButton
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentPage == .paywall {
                        Image(icon: .close)
                            .button {
                                AnalyticsService.shared.track(.onboardingPaywallSkipped)
                                completeOnboarding(skippedPaywall: true)
                            }
                    }
                }
            }
        }
    }
    
    private func handleNext() {
        let analytics = AnalyticsService.shared
        switch currentPage {
        case .welcome:
            analytics.track(.onboardingWelcome)
            withAnimation(.easeInOut(duration: 0.3)) { currentPage = .agents }
        case .agents:
            withAnimation(.easeInOut(duration: 0.3)) { currentPage = .deadline }
        case .deadline:
            analytics.track(.onboardingDeadline)
            withAnimation(.easeInOut(duration: 0.3)) { currentPage = .name }
        case .name:
            analytics.track(.onboardingName, metadata: ["has_name": !userName.isEmpty])
            withAnimation(.easeInOut(duration: 0.3)) { currentPage = .notifiation }
        case .notifiation:
            if notificationsEnabled || notificationsDenied {
                analytics.track(.onboardingNotifications, metadata: [
                    "granted": notificationsEnabled,
                    "denied": notificationsDenied
                ])
                withAnimation(.easeInOut(duration: 0.3)) {
                    if isPro {
                        completeOnboarding(skippedPaywall: true)
                    } else {
                        analytics.track(.onboardingPaywallShown)
                        currentPage = .paywall
                    }
                }
            } else {
                Task {
                    let granted = await NagService.shared.requestPermission()
                    if granted {
                        await MainActor.run {
                            withAnimation { notificationsEnabled = true }
                        }
                    } else {
                        let status = await NagService.shared.permissionStatus()
                        if status == .denied {
                            await MainActor.run {
                                withAnimation { notificationsDenied = true }
                            }
                        }
                    }
                }
            }
            
        case .paywall:
            completeOnboarding(skippedPaywall: false)
        }
    }
    
    // MARK: - Complete Onboarding
    
    @MainActor
    private func completeOnboarding(skippedPaywall: Bool) {
        AnalyticsService.shared.track(.onboardingCompleted, metadata: [
            "skipped_paywall": skippedPaywall,
            "agent": selectedAgent?.rawValue ?? "none"
        ])
        if let agent = selectedAgent {
            Task { await DeviceService.shared.saveOnboardingAgent(agent.rawValue) }
        }
        withAnimation {
            completedOnboarding = true
        }
    }
    
    // MARK: - Paywall Button
    private var payWallButton: some View {
        VStack(spacing: 0) {
            payButton
            // Restore
            Button(L10n.Paywall.restorePurchase) {
                Task { await store.restore() }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
                .padding(.top, 15)
        }
    }
    
    private var payButton: some View {
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
            Task {
                await store.purchase()
                if isPro {
                    AnalyticsService.shared.track(.onboardingPaywallPurchased)
                }
            }
        }
        .disabled(store.isLoading || store.product == nil)
    }
    
    private var userNameButton: some View {
        VStack {
            Spacer()
            HStack {
                Text(L10n.Common.cancel)
                    .padding(.horizontal)
                    .button {
                        userName = ""
                        isFocused = false
                    }
                    .buttonStyle(.plain)
                Spacer()
                Circle()
                    .frame(width: 30)
                    .foregroundStyle(.blue)
                    .overlay(
                        Image(icon: .checkmark)
                            .foregroundStyle(.white)
                    )
                    .button {
                        isFocused = false
                    }
                    .disabled(userName.count < 2)
                    .glassEffect(in: .circle)
                    .padding()
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(StoreManager())
}
