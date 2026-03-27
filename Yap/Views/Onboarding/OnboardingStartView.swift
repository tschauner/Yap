//
//  OnboardingStartView.swift
//  Yap
//
//  Created by Philipp Tschauner on 16.03.26.
//

import SwiftUI

struct OnboardingStartView: View {

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
                .frame(height: 200)
            
            Image("icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .glassEffect(in: .rect(cornerRadius: 22))
                .zIndex(1)

            VStack(spacing: 15) {
                Headline(text: L10n.Onboarding.headline)
                    .padding(.horizontal, 30)
                    .background(
                        AuroraView()
                            .frame(width: 280, height: 280)
                            .opacity(0.7)
                            .allowsHitTesting(false)
                    )
                    .zIndex(0)
                
                Text(L10n.Onboarding.subline)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.secondary)
                
                
                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
    }
}

#Preview {
    OnboardingStartView()
}
