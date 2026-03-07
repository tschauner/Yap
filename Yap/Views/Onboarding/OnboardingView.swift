// OnboardingView.swift
// Yap

import SwiftUI

struct OnboardingView: View {
    
    enum Page: CaseIterable {
        case welcome
        case agents
        case sleepTime
        case notifiation
        case store
        case fisnih
        
        var canBeSkipped: Bool {
            switch self {
            case .notifiation, .welcome:
                return false
            default:
                return true
            }
        }
    }
    
    @AppStorage("completedOnboarding") var completedOnboarding = false
    @AppStorage(QuietHours.startKey) private var quietHoursStart: Int = QuietHours.defaultStart
    @AppStorage(QuietHours.endKey) private var quietHoursEnd: Int = QuietHours.defaultEnd
    
    @State private var currentPage: Page = .welcome
    @State private var selectedAgent: Agent = .mom
    @State private var quietStart = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var quietEnd = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    
    private let totalPages = 5
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            TabView(selection: $currentPage) {
                valuePropScreen.tag(Page.welcome)
                agentsScreen.tag(Page.agents)
                notificationsScreen.tag(Page.notifiation)
                quietHoursScreen.tag(Page.sleepTime)
                readyScreen.tag(Page.fisnih)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            // Bottom
            VStack(spacing: 16) {
                // Page Indicator
//                HStack(spacing: 6) {
//                    ForEach(Page.allCases, id: \.self) { page in
//                        Circle()
//                            .fill(currentPage == page ? Color.primary : Color.primary.opacity(0.2))
//                            .frame(width: 6, height: 6)
//                    }
//                }
                
                // Button
                Button {
                    handleNext()
                } label: {
                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    private var buttonTitle: String {
        switch currentPage {
        case .notifiation: return "Allow Notifications"
        case .fisnih: return "Let's go"
        case .store: return "Subscribe"
        default: return "Next"
        }
    }
    
    private func handleNext() {
        switch currentPage {
        case .welcome:
            currentPage = .agents
        case .notifiation:
            // Request notification permission
            Task {
                await NagService.shared.requestPermission()
                await MainActor.run { currentPage = .fisnih }
            }
        case .sleepTime:
            // Save quiet hours
            quietHoursStart = Calendar.current.component(.hour, from: quietStart)
            quietHoursEnd = Calendar.current.component(.hour, from: quietEnd)
            currentPage = .store
        case .store:
            currentPage = .fisnih
        case .fisnih:
            completedOnboarding = true
        case .agents:
            currentPage = .sleepTime
        }
    }
    
    // MARK: - Screen 1: Value Prop
    
    private var valuePropScreen: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 10) {
                Text("Pick one thing.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 26, weight: .bold))
                
                Text("Get nagged until you finish.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 26, weight: .bold))
                
                Text("That's it.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 26, weight: .bold))
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }
    
    private func flowStep(number: String, text: String) -> some View {
        HStack(spacing: 14) {
            Text(number)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.black)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Screen 2: Agents
    
    private var agentsScreen: some View {
        VStack(spacing: 0) {
            Spacer()
        
            
            Text(selectedAgent.pitch)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .animation(.easeOut(duration: 0.2), value: selectedAgent)
                .frame(height: 50, alignment: .topLeading)
                .padding(.bottom, 30)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Agent.allCases, id: \.self) { agent in
                    agentCell(agent)
                }
            }
            .padding(.bottom, 100)
            
            Text("Meet your agents.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 26, weight: .bold))
                .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }
    
    private func agentCell(_ agent: Agent) -> some View {
        VStack(spacing: 8) {
            Text(agent.emoji)
                .font(.system(size: 36))
            Text(agent.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(selectedAgent == agent ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(selectedAgent == agent ? Color.primary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(selectedAgent == agent ? Color.primary : Color.clear, lineWidth: 1.5)
        )
        .onTapGesture {
            selectedAgent = agent
        }
    }
    
    // MARK: - Screen 3: Notifications
    
    private var notificationsScreen: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Your agent needs notifications to nag you.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 26, weight: .bold))
                
                Text("Without them, we're just a fancy to-do list.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Screen 4: Quiet Hours
    
    private var quietHoursScreen: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("No notifications between these times.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 26, weight: .bold))
                .padding(.bottom, 20)
            
            VStack(spacing: 10) {
                HStack {
                    Text("From")
                    Spacer()
                    DatePicker("", selection: $quietStart, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                .padding(20)
                .background(.quinary)
                .cornerRadius(20)
                
                HStack {
                    Text("Until")
                    Spacer()
                    DatePicker("", selection: $quietEnd, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                .padding(20)
                .background(.quinary)
                .cornerRadius(20)
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Screen 5: Ready
    
    private var readyScreen: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("You're all set.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 26, weight: .bold))
                .padding(.bottom, 8)
            
            Text("Time for your first mission.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    OnboardingView()
}
