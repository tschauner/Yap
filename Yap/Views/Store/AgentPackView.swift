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
                .foregroundStyle(.yellow)
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
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("\(displayName) 3 Agents")
                            .font(.system(size: 17, weight: .bold))
                    }
                }

                Spacer()

                if !isPurchased {
                    buyButton
                }
            }
            .padding(.bottom, 20)

            // Agent bubbles
            HStack(spacing: 0) {
                ForEach(pack.agents, id: \.self) { agent in
                    AgentBubble(agent: agent)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 10)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.quaternarySystemFill))
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
        HStack {
            if case .loading = packStore.purchaseState {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
            } else {
                Text(priceString)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.blue)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 70, height: 30)
        .foregroundStyle(.white)
        .background(.quinary, in: Capsule())
        .button {
            Task { await packStore.purchase(pack) }
        }
        .buttonStyle(.plain)
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
