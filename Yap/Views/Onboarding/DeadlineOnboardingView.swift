//
//  DeadlineOnboardingView.swift
//  Yap
//
//  Created by Philipp Tschauner on 16.03.26.
//

import SwiftUI

struct DeadlineOnboardingView: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Headline(text: L10n.Onboarding.deadlineHeadline)
                    .background(
                        AuroraView()
                            .frame(width: 280, height: 280)
                            .opacity(0.7)
                            .allowsHitTesting(false)
                    )
                
                Subline(text: L10n.Onboarding.deadlineSubline)
                    .padding(.top, 15)
            }
            .padding(.horizontal, .horizontal)
            .padding(.bottom, 40)
            
            VStack(spacing: 0) {
                emojis
                .frame(maxWidth: .infinity)
                
                HStack {
                    Text(L10n.Onboarding.start)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    
                    Text(L10n.Onboarding.deadline)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                }
                .padding(.top, 15)
                .padding(.horizontal, 20)
            }
            .frame(height: 90)
            .cornerRadius(30)
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal, .horizontal)
        }
    }
    
    var emojis: some View {
        HStack(spacing: 5) {
            Text("😊")
                .frame(width: 40, height: 30, alignment: .center)
                .font(.system(size: 30))
            
            Image(icon: .arrowRight)
            
            Text("😐")
                .frame(width: 40, height: 30, alignment: .center)
                .font(.system(size: 30))
            
            Image(icon: .arrowRight)
            
            Text("😠")
                .frame(width: 40, height: 30, alignment: .center)
                .font(.system(size: 30))
            
            Image(icon: .arrowRight)
            
            Text("🤬")
                .frame(width: 40, height: 30, alignment: .center)
                .font(.system(size: 30))
            
            Image(icon: .arrowRight)
            
            Text("💀")
                .frame(width: 40, height: 30, alignment: .center)
                .font(.system(size: 30))
        }
    }
}

#Preview {
    DeadlineOnboardingView()
}
