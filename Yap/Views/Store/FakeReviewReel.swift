//
//  FakeReviewReel.swift
//  Yap
//
//  Created by Philipp Tschauner on 29.03.26.
//

import SwiftUI

struct PaywallReview: Identifiable {
    let id = UUID().uuidString
    let body: String
    let name: String
}

struct FakeReviewReel: View {
    var leadingPadding: CGFloat = 30
    
    private var paywallReviews: [PaywallReview] { L10n.FakeReview.all }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 15) {
                ForEach(paywallReviews) { review in
                    reviewCard(for: review)
                }
            }
            .padding(.leading, leadingPadding)
        }
        .scrollIndicators(.hidden)
    }
    
    private func reviewCard(for review: PaywallReview) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 1) {
                Image(icon: .starFilled)
                Image(icon: .starFilled)
                Image(icon: .starFilled)
                Image(icon: .starFilled)
                Image(icon: .starFilled)
            }
            .font(.system(size: 14))
            .foregroundStyle(.yellow.gradient)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom)
            
            Text(review.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 15, weight: .medium))
                .padding(.bottom)
            Text(review.name)
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)
        }
        .frame(width: 250, height: 100)
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}

#Preview {
    FakeReviewReel()
}
