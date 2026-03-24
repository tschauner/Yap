//
//  OnboardingStartView.swift
//  Yap
//
//  Created by Philipp Tschauner on 16.03.26.
//

import SwiftUI

struct OnboardingStartView: View {
    @State var onAppear = false
    
    var body: some View {
        VStack(spacing: 32) {
            Image("grid")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
            
            HStack(spacing: 1) {
                Image("single_quote")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
                    .offset(y: onAppear ? 0 : -30)
                Image("single_quote")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
                    .offset(y: onAppear ? 0 : 30)
            }
            
            VStack(spacing: 15) {
                Headline(text: L10n.Onboarding.headline)
                
                Text(L10n.Onboarding.subline)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.secondary)
                
                
                Spacer()
            }
            .padding(.horizontal, 50)
            .padding(.top, 10)
        }
        .onAppear {
            withAnimation(.bouncy(extraBounce: 0.15)) {
                onAppear = true
            }
        }
        .onDisappear {
            onAppear = false
        }
    }
}

#Preview {
    OnboardingStartView()
}
