// OnboardingNameView.swift
// Yap

import SwiftUI

struct OnboardingNameView: View {
    @AppStorage("user_display_name") private var userName: String = ""
    @FocusState var isFocused
    @Binding var focused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 0) {
                Headline(text: L10n.Onboarding.nameHeadline)
                    .background(
                        AuroraView()
                            .frame(width: 280, height: 280)
                            .opacity(0.7)
                            .allowsHitTesting(false)
                    )
                
                Subline(text: L10n.Onboarding.nameSubline)
                    .padding(.top, 15)
            }
            .padding(.horizontal, 50)
            
            TextField(L10n.Onboarding.namePlaceholder, text: $userName)
                .focused($isFocused)
                .font(.system(size: 20, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
//                .background(.quinary)
                .clipShape(Capsule())
                .glassEffect(in: .capsule)
                .padding(.horizontal, 50)
                .submitLabel(.continue)
                .autocorrectionDisabled()
                .padding(.top, 20)
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
            
            if !isFocused {
                Spacer()
            }
        }
        .onChange(of: isFocused) { _, newValue in
            focused = newValue
        }
        .onChange(of: focused) { _, newValue in
            isFocused = newValue
        }
    }
}

#Preview {
    OnboardingNameView(focused: .constant(false))
}
