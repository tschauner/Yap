// OnboardingView.swift
// Yap

import SwiftUI

/// Multi-Step Onboarding: Welcome → How it works → Notifications → Pick free agent → (Optional: Paywall) → Done
struct OnboardingView: View {
    var onComplete: () -> Void
    
    @State private var page = 0
    @State private var notificationsGranted = false
    
    private let totalPages = 4
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Circle()
                        .fill(i <= page ? Color.primary : Color.primary.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 16)
            
            TabView(selection: $page) {
                welcomePage.tag(0)
                howItWorksPage.tag(1)
                notificationPage.tag(2)
                readyPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.snappy(duration: 0.4), value: page)
        }
    }
    
    // MARK: - Page 1: Welcome
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("🗣️")
                .font(.system(size: 80))
            
            VStack(spacing: 12) {
                Text("Welcome to Yap")
                    .font(.system(size: 32, weight: .bold))
                
                Text("The app that won't shut up\nuntil you get things done.")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            onboardingButton("Let's go") {
                page = 1
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Page 2: How it works
    
    private var howItWorksPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("How it works")
                .font(.system(size: 28, weight: .bold))
            
            VStack(alignment: .leading, spacing: 24) {
                howItWorksRow(
                    emoji: "✍️",
                    title: "Set a goal",
                    subtitle: "What do you need to get done today?"
                )
                howItWorksRow(
                    emoji: "🤖",
                    title: "Pick your agent",
                    subtitle: "Choose who'll remind you — nice or not."
                )
                howItWorksRow(
                    emoji: "📈",
                    title: "It escalates",
                    subtitle: "The longer you wait, the more intense it gets."
                )
                howItWorksRow(
                    emoji: "✅",
                    title: "Mark it done",
                    subtitle: "The only way to make it stop."
                )
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            onboardingButton("Got it") {
                page = 2
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Page 3: Notifications
    
    private var notificationPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("🔔")
                .font(.system(size: 80))
            
            VStack(spacing: 12) {
                Text("Notifications are\nkind of the point")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Without them, we're just\na fancy to-do list.")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            onboardingButton(notificationsGranted ? "Continue" : "Enable notifications") {
                if notificationsGranted {
                    page = 3
                } else {
                    Task {
                        let granted = await NagService.shared.requestPermission()
                        notificationsGranted = granted
                        // Auch wenn abgelehnt, weitermachen
                        page = 3
                    }
                }
            }
            
            if !notificationsGranted {
                Button("Maybe later") {
                    page = 3
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Page 4: Ready
    
    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("😤")
                .font(.system(size: 80))
            
            VStack(spacing: 12) {
                Text("You're in for it now")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Set your first goal.\nWe dare you to ignore it.")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            onboardingButton("Let's do this") {
                onComplete()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Components
    
    private func howItWorksRow(emoji: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 48)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func onboardingButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
