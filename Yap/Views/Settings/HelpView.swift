// HelpView.swift
// Yap

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            List {
                // Community & Feedback
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 17))
                            .foregroundStyle(.indigo)
                            .frame(width: 28)
                        Text("Join the Community")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .button {
                        openURL(URL(string: "https://discord.gg/yap")!)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 17))
                            .foregroundStyle(.orange)
                            .frame(width: 28)
                        Text("Request a Feature")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .button {
                        openURL(URL(string: "https://userjot.com/")!)
                    }
                } header: {
                    Text("Community & Feedback")
                } footer: {
                    Text("Vote on features and help shape Yap.")
                }
                
                // FAQ
                Section {
                    faqItem(
                        question: "What is Yap?",
                        answer: "Yap uses AI agents with unique personalities to motivate you to finish tasks. Pick an agent, describe your mission, and get nudged until you're done."
                    )
                    
                    faqItem(
                        question: "How does the free plan work?",
                        answer: "You get Mom as your free agent with 1 mission per day. AI-powered messages, leaderboard, and quiet hours are included for everyone."
                    )
                    
                    faqItem(
                        question: "What does Pro unlock?",
                        answer: "All 6 agents, unlimited daily missions, and the ability to extend deadlines."
                    )
                    
                    faqItem(
                        question: "What happens when I miss a deadline?",
                        answer: "The mission counts as failed and affects your stats. Your agent won't be happy about it either."
                    )
                    
                    faqItem(
                        question: "Can I extend a deadline?",
                        answer: "Pro users can extend a deadline once per mission by 24 hours."
                    )
                    
                    faqItem(
                        question: "What are quiet hours?",
                        answer: "Set a time window where agents won't send notifications. They'll resume bugging you after."
                    )
                    
                    faqItem(
                        question: "How do agents differ?",
                        answer: "Each agent has a unique personality and communication style — from Mom's guilt trips to Drill Sergeant's tough love. Try them all to find your match."
                    )
                } header: {
                    Text("FAQ")
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func faqItem(question: String, answer: String) -> some View {
        DisclosureGroup {
            Text(answer)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        } label: {
            Text(question)
                .font(.system(size: 15, weight: .medium))
        }
    }
}

#Preview {
    HelpView()
}
