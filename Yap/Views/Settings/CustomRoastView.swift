//
//  CustomRoastView.swift
//  Yap
//
//  Created by Philipp Tschauner on 12.03.26.
//

import SwiftUI

struct CustomRoastView: View {
    @AppStorage("customRoast") private var customRoast: String = ""
    @FocusState private var isFocused: Bool
    
    private let maxLength = 200
    private let placeholder = L10n.CustomRoast.placeholder
    
    var body: some View {
        List {
            Section {
                ZStack(alignment: .topLeading) {
                    if customRoast.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $customRoast)
                        .focused($isFocused)
                        .frame(minHeight: 100)
                        .onChange(of: customRoast) { _, newValue in
                            if newValue.count > maxLength {
                                customRoast = String(newValue.prefix(maxLength))
                            }
                        }
                }
                
                HStack {
                    Spacer()
                    Text("\(customRoast.count)/\(maxLength)")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            } header: {
                Text(L10n.CustomRoast.sectionHeader)
            } footer: {
                Text(L10n.CustomRoast.sectionFooter)
            }
        }
        .navigationTitle(L10n.CustomRoast.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isFocused = true }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if !customRoast.isEmpty {
                    Image(icon: .trash)
                        .foregroundStyle(.red)
                        .button {
                            customRoast = ""
                        }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CustomRoastView()
    }
}
