// AgentPackView.swift
// Yap

import SwiftUI
import StoreKit

struct AgentPackView: View {
    @EnvironmentObject var packStore: AgentPackStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(AgentPack.allCases) { pack in
                        PackCard(pack: pack)
                    }

                    restoreButton
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("More Agents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await packStore.loadProducts() }
        }
    }

    private var restoreButton: some View {
        Button {
            Task { await packStore.restore() }
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Pack Card

private struct PackCard: View {
    @EnvironmentObject var packStore: AgentPackStore
    @Environment(\.colorScheme) private var colorScheme
    let pack: AgentPack

    private var product: Product? { packStore.product(for: pack) }
    private var isPurchased: Bool { packStore.isPurchased(pack) }

    private var displayName: String {
        product?.displayName ?? pack.fallbackName
    }

    private var displayDescription: String {
        product?.description ?? pack.fallbackDescription
    }

    private var priceString: String {
        product?.displayPrice ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(pack.emoji)
                            .font(.system(size: 22))
                        Text(displayName)
                            .font(.system(size: 19, weight: .bold))
                    }
                    Text(displayDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                purchasedBadge
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 12)

            // Agent bubbles
            HStack(spacing: 0) {
                ForEach(pack.agents, id: \.self) { agent in
                    AgentBubble(agent: agent)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)

            // CTA
            if !isPurchased {
                buyButton
                    .padding([.horizontal, .bottom], 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Subviews

    @ViewBuilder
    private var purchasedBadge: some View {
        if isPurchased {
            Label("Owned", systemImage: "checkmark.seal.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.12), in: Capsule())
        }
    }

    private var buyButton: some View {
        Button {
            Task { await packStore.purchase(pack) }
        } label: {
            HStack {
                if case .loading = packStore.purchaseState {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Get Pack · \(priceString)")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .background(Color.primary, in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(packStore.purchaseState == .loading)
    }
}

// MARK: - Agent Bubble

private struct AgentBubble: View {
    let agent: Agent

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(agent.accentColor.gradient)
                .frame(width: 58, height: 58)
                .overlay(
                    Text(agent.emoji)
                        .font(.system(size: 28))
                )

            Text(agent.displayName)
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

// MARK: - Preview

#Preview {
    AgentPackView()
        .environmentObject(AgentPackStore())
}
