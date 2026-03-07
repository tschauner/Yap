// SettingsView.swift
// Yap

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var auth = AuthService.shared
    @AppStorage(QuietHours.startKey) private var quietHoursStart: Int = QuietHours.defaultStart
    @AppStorage(QuietHours.endKey) private var quietHoursEnd: Int = QuietHours.defaultEnd
    
    @State private var quietStart: Date = Date()
    @State private var quietEnd: Date = Date()
    @State private var showUnlinkAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Quiet Hours
                Section {
                    HStack {
                        Text("From")
                        Spacer()
                        DatePicker("", selection: $quietStart, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Until")
                        Spacer()
                        DatePicker("", selection: $quietEnd, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                } header: {
                    Text("Quiet Hours")
                } footer: {
                    Text("No notifications between these times.")
                }
                
                // Account
                Section {
                    if auth.isLinked {
                        // Linked state
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Synced with Apple ID")
                            Spacer()
                        }
                        
                        Button(role: .destructive) {
                            showUnlinkAlert = true
                        } label: {
                            HStack {
                                Text("Unlink Account")
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
                            Text("Sign in with Apple to sync your data across devices.")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            
                            Button {
                                auth.signInWithApple()
                            } label: {
                                HStack {
                                    Image(systemName: "apple.logo")
                                    Text("Sign in with Apple")
                                }
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .disabled(auth.isLoading)
                            .overlay {
                                if auth.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Account")
                } footer: {
                    if !auth.isLinked {
                        Text("Your data stays on this device until you link it.")
                    }
                }
                
                // Device Info
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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveQuietHours()
                        dismiss()
                    }
                }
            }
            .onAppear {
                quietStart = timeFromHour(quietHoursStart)
                quietEnd = timeFromHour(quietHoursEnd)
            }
            .alert("Unlink Account?", isPresented: $showUnlinkAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Unlink", role: .destructive) {
                    Task { await auth.unlinkAccount() }
                }
            } message: {
                Text("Your data will stay on this device but won't sync to new devices.")
            }
        }
    }
    
    private func saveQuietHours() {
        quietHoursStart = Calendar.current.component(.hour, from: quietStart)
        quietHoursEnd = Calendar.current.component(.hour, from: quietEnd)
    }
    
    private func timeFromHour(_ hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    SettingsView()
}
