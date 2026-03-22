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
            Image("grid")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
                
            Image("quote")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 60)
            
            VStack(spacing: 15) {
                Text(L10n.Onboarding.headline)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text(L10n.Onboarding.subline)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.secondary)
                
                
                Spacer()
            }
            .padding(.horizontal, 50)
            .padding(.top, 10)
        }
    }
}

#Preview {
    OnboardingStartView()
}
