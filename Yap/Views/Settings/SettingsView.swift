// SettingsView.swift
// Yap

import SwiftUI
import StoreKit
import Combine
import AuthenticationServices

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StoreManager
    @StateObject private var auth = AuthService.shared
    @State private var showUnlinkAlert = false
    @AppStorage("customRoast") private var customRoast: String = ""
    @AppStorage("hapticFeedbackEnabled") private var isOn: Bool = true
    @Environment(\.requestReview) private var requestReview
    
    private let appURL = URL(string: "https://apps.apple.com/app/id6738916276")!
    
    var body: some View {
        NavigationStack {
            List {
                // Account
                appleSignInSection
                
                // Personalization
                Section {
                    NavigationLink {
                        CustomRoastView()
                    } label: {
                        HStack {
                            Text(L10n.Settings.customRoast)
                            Spacer()
                            if !customRoast.isEmpty {
                                Text(L10n.Settings.customRoastActive)
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    
                } header: {
                    Text(L10n.Settings.sectionPersonalization)
                } footer: {
                    Text(L10n.Settings.personalizationFooter)
                }
                
                // General
                Section {
                    Toggle(L10n.Settings.hapticFeedback, isOn: $isOn)
                    
                    Button {
                        requestReview()
                    } label: {
                        HStack {
                            Text(L10n.Settings.reviewYap)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(icon: .star)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    ShareLink(item: appURL) {
                        HStack {
                            Text(L10n.Settings.shareYap)
                            Spacer()
                            Image(icon: .share)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        Task { await store.restore() }
                    } label: {
                        HStack {
                            Text(L10n.Settings.restorePurchases)
                                .foregroundStyle(.primary)
                            if store.isLoading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                } header: {
                    Text(L10n.Settings.sectionGeneral)
                }

                // Legal
                Section {
                    Link(L10n.Legal.privacyPolicy, destination: URL(string: "https://yap.fail/privacy")!)
                    Link(L10n.Legal.termsOfUse, destination: URL(string: "https://yap.fail/terms")!)
                } header: {
                    Text(L10n.Settings.sectionLegal)
                }
                
                // Debug (only in debug builds)
                #if DEBUG
                Section {
                    HStack {
                        Text("Device ID")
                        Spacer()
                        Text(String(APIClient.deviceId.prefix(8)) + "...")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14, design: .monospaced))
                    }
                } header: {
                    Text("Debug")
                }
                #endif
            }
            .navigationTitle(L10n.Settings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                }
            }
            .alert(L10n.Settings.unlinkAlertTitle, isPresented: $showUnlinkAlert) {
                Button(L10n.Common.cancel, role: .cancel) { }
                Button(L10n.Settings.unlinkAction, role: .destructive) {
                    Task { await auth.unlinkAccount() }
                }
            } message: {
                Text(L10n.Settings.unlinkAlertMessage)
            }
        }
    }
    
    var appleSignInSection: some View {
        Section {
            if auth.isLinked {
                // Linked state
                HStack {
                    Image(icon: .checkmarkCircle)
                        .foregroundStyle(.green)
                    Text(L10n.Settings.accountSynced)
                    Spacer()
                }
                
                Button(role: .destructive) {
                    showUnlinkAlert = true
                } label: {
                    HStack {
                        Text(L10n.Settings.unlinkAccount)
                        if auth.isLoading {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(auth.isLoading)
            } else {
                // Not linked
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Settings.signInDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = []
                        auth.isLoading = true
                        auth.error = nil
                    } onCompletion: { result in
                        auth.handleSignInResult(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .disabled(auth.isLoading)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text(L10n.Settings.sectionAccount)
        } footer: {
            if !auth.isLinked {
                Text(L10n.Settings.notLinkedFooter)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StoreManager())
}
