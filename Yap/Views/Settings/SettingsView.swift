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
    @State private var showPaywall = false
    @AppStorage("customRoast") private var customRoast: String = ""
    @AppStorage("hapticFeedbackEnabled") private var isOn: Bool = true
    @Environment(\.requestReview) private var requestReview
    
    private let appURL = URL(string: "https://apps.apple.com/app/id6761190023")!
    
    var body: some View {
        NavigationStack {
            List {
                // Account
                appleSignInSection
                
                // Personalization
                Section {
                    NavigationLink {
                        NameDetailView()
                    } label: {
                        HStack {
                            Text(L10n.Settings.name)
                            Spacer()
                            Text(UserDefaults.standard.string(forKey: "user_display_name")?.isEmpty == false
                                 ? UserDefaults.standard.string(forKey: "user_display_name")!
                                 : L10n.Settings.nameNotSet)
                                .foregroundStyle(.secondary)
                                .font(.system(size: 14))
                        }
                    }
                    
                    if ProAccess.isPro {
                        NavigationLink {
                            CustomRoastView()
                        } label: {
                            customRoastLabel
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            customRoastLabel
                        }
                        .foregroundStyle(.primary)
                    }
                    
                    NavigationLink {
                        QuietHoursDetailView()
                    } label: {
                        HStack {
                            Text(L10n.QuietHours.title)
                            Spacer()
                            Text(QuietHours.isEnabled ? QuietHours.formattedRange : L10n.Common.off)
                                .foregroundStyle(.secondary)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Toggle(L10n.Settings.hapticFeedback, isOn: $isOn)
                    
                } header: {
                    Text(L10n.Settings.sectionPersonalization)
                }
                
                // General
                Section {
                    if !ProAccess.isPro {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Text("Yap Pro")
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(L10n.Settings.upgrade)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.gradient)
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        requestReview()
                    } label: {
                        Text(L10n.Settings.reviewYap)
                    }
                    .buttonStyle(.plain)
                    
                    ShareLink(item: appURL) {
                        Text(L10n.Settings.shareYap)
                    }
                    .buttonStyle(.plain)
                    
                    Link(L10n.Legal.privacyPolicy, destination: URL(string: "https://yap.fail/privacy")!)
                        .buttonStyle(.plain)
                    Link(L10n.Legal.termsOfUse, destination: URL(string: "https://yap.fail/terms")!)
                        .buttonStyle(.plain)
                    
                } header: {
                    Text(L10n.Settings.sectionGeneral)
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }

        }
    }
    
    private var customRoastLabel: some View {
        HStack {
            Text(L10n.Settings.customRoast)
            if !ProAccess.isPro {
                Text("PRO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue)
                    .clipShape(Capsule())
            }
            Spacer()
            if ProAccess.isPro && !customRoast.isEmpty {
                Text(L10n.Settings.customRoastActive)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
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
