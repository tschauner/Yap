// GoalInputView.swift
// Yap

import SwiftUI

/// Hauptscreen: nur ein Textfeld, minimalistisch.
struct GoalInputView: View {
    @Binding var text: String
    var onSubmit: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            TextField("What do you need to do?", text: $text, axis: .vertical)
                .font(.system(size: 28, weight: .medium))
                .lineLimit(1...4)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSubmit()
                    }
                }
            
            Spacer()
            
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: onSubmit) {
                    Text("Next")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .animation(.snappy(duration: 0.3), value: text.isEmpty)
        .onAppear { isFocused = true }
    }
}
