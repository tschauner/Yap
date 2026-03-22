// FlowLayout.swift
// Yap

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentY += rowHeight + spacing
                currentX = 0
                rowHeight = 0
            }
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX - spacing)
            rowHeight = max(rowHeight, size.height)
            totalHeight = currentY + rowHeight
        }

        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let containerWidth = bounds.width

        // First pass: compute rows
        var rows: [[LayoutSubviews.Element]] = [[]]
        var rowWidths: [CGFloat] = [0]
        var currentX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                rows.append([])
                rowWidths.append(0)
                currentX = 0
            }
            rows[rows.count - 1].append(subview)
            if currentX > 0 {
                currentX += spacing
            }
            currentX += size.width
            rowWidths[rowWidths.count - 1] = currentX
        }

        // Second pass: place subviews centered per row
        var y: CGFloat = bounds.minY

        for (index, row) in rows.enumerated() {
            let rowWidth = rowWidths[index]
            var x = bounds.minX + (containerWidth - rowWidth) / 2
            var rowHeight: CGFloat = 0

            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }

            y += rowHeight + spacing
        }
    }
}
