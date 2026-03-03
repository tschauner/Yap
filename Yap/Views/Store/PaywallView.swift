// PaywallView.swift
// Yap

import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Close
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Spacer()
            
            // Headline
            VStack(spacing: 12) {
                Text("🔓")
                    .font(.system(size: 64))
                
                Text("Unlock all agents")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Get AI-powered reminders that\nactually know what you're doing.")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Feature list
            VStack(alignment: .leading, spacing: 16) {
                featureRow("🤖", "All 5 agents", "Drill Sergeant, Coach, Chaos & more")
                featureRow("✨", "AI-generated messages", "Unique reminders tailored to your goal")
                featureRow("♾️", "Unlimited goals", "Set as many as you need")
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Purchase button
            VStack(spacing: 12) {
                Button {
                    Task { await store.purchase() }
                } label: {
                    Group {
                        if store.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else if let product = store.product {
                            Text("Get Yap Pro — \(product.displayPrice)")
                                .font(.system(size: 18, weight: .bold))
                        } else {
                            Text("Get Yap Pro")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.orange.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(store.isLoading || store.product == nil)
                
                Text("One-time purchase. No subscription.")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                
                Button("Restore purchase") {
                    Task { await store.restore() }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onChange(of: store.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }
    
    private func featureRow(_ emoji: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 28))
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
