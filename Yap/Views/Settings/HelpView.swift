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
                        Text(L10n.Help.joinCommunity)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .button {
                        openURL(URL(string: "https://discord.gg/eK6hUZKs")!)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 17))
                            .foregroundStyle(.orange)
                            .frame(width: 28)
                        Text(L10n.Help.requestFeature)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .button {
                        openURL(URL(string: "https://yapapp.userjot.com/")!)
                    }
                } header: {
                    Text(L10n.Help.sectionCommunity)
                } footer: {
                    Text(L10n.Help.communityFooter)
                }
                
                // FAQ
                Section {
                    faqItem(
                        question: L10n.Help.faqWhatIsYapQ,
                        answer: L10n.Help.faqWhatIsYapA
                    )
                    
                    faqItem(
                        question: L10n.Help.faqFreePlanQ,
                        answer: L10n.Help.faqFreePlanA
                    )
                    
                    faqItem(
                        question: L10n.Help.faqProUnlockQ,
                        answer: L10n.Help.faqProUnlockA
                    )
                    
                    faqItem(
                        question: L10n.Help.faqMissDeadlineQ,
                        answer: L10n.Help.faqMissDeadlineA
                    )
                    
                    faqItem(
                        question: L10n.Help.faqExtendDeadlineQ,
                        answer: L10n.Help.faqExtendDeadlineA
                    )
                    
                    faqItem(
                        question: L10n.Help.faqNightNotificationsQ,
                        answer: L10n.Help.faqNightNotificationsA
                    )
                    
                    faqItem(
                        question: L10n.Help.faqAgentDifferencesQ,
                        answer: L10n.Help.faqAgentDifferencesA
                    )
                } header: {
                    Text(L10n.Help.sectionFaq)
                }
            }
            .navigationTitle(L10n.Help.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) { dismiss() }
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
