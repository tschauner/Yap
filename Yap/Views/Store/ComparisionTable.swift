//
//  ComparisionTable.swift
//  Yap
//
//  Created by Philipp Tschauner on 18.03.26.
//

import SwiftUI

struct ComparisionTable: View {
    var body: some View {
        comparisonTable
    }
    
    private var comparisonTable: some View {
        VStack(spacing: 0) {
            // Table header
            HStack {
                Spacer()
                Text(L10n.Comparison.free)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 56)
                Text(L10n.Comparison.pro)
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 56)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            // Rows
            comparisonRow(L10n.Comparison.specialAgents, free: false, pro: true)
            comparisonRow(L10n.Comparison.missionsPerDay, free: L10n.Comparison.missionsPerDayFree, pro: L10n.Comparison.missionsPerDayPro)
            comparisonRow(L10n.Comparison.aiMessages, free: true, pro: true)
            comparisonRow(L10n.Comparison.agentMemory, free: false, pro: true)
            comparisonRow(L10n.Comparison.customRoast, free: false, pro: true)
            comparisonRow(L10n.Comparison.customDeadline, free: false, pro: true)
            comparisonRow(L10n.Comparison.extend24h, free: false, pro: true, showDivider: false)
        }
        .padding(.vertical, 16)
    }
    
    private func comparisonRow(_ label: String, free: Bool, pro: Bool, showDivider: Bool = true) -> some View {
        comparisonRowContent(label, content: {
            checkOrDash(free, highlighted: false)
                .frame(width: 56)
            checkOrDash(pro, highlighted: true)
                .frame(width: 56)
        }, showDivider: showDivider)
    }
    
    private func comparisonRow(_ label: String, free: String, pro: String, showDivider: Bool = true) -> some View {
        comparisonRowContent(label, content: {
            Text(free)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 56)
            Text(pro)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 56)
                .frame(width: 56)
        }, showDivider: showDivider)
    }
    
    private func comparisonRowContent<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content,
        showDivider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                Spacer()
                content()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, showDivider ? 14 : 0)
            
            if showDivider {
                Divider()
                    .padding(.horizontal, 16)
            }
        }
    }
    
    @ViewBuilder
    private func checkOrDash(_ value: Bool, highlighted: Bool) -> some View {
        if value {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(highlighted ? Color.primary : .secondary)
        } else {
            Text("–")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.quaternary)
        }
    }
}

#Preview {
    ComparisionTable()
}
