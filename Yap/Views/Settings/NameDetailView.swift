// NameDetailView.swift
// Yap

import SwiftUI

struct NameDetailView: View {
    @AppStorage("user_display_name") private var userName: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        List {
            Section {
                TextField(L10n.Onboarding.namePlaceholder, text: $userName)
                    .focused($isFocused)
                    .autocorrectionDisabled()
            } footer: {
                Text(L10n.Settings.nameFooter)
            }
        }
        .navigationTitle(L10n.Settings.name)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        NameDetailView()
    }
}
