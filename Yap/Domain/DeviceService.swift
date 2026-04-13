// DeviceService.swift
// Yap

import Foundation
internal import UIKit

/// Manages device registration for remote push notifications.
/// Stores the APNs token and syncs device metadata to Supabase (yap_devices).
final class DeviceService: @unchecked Sendable {
    
    static let shared = DeviceService()
    
    private let api: APIClient
    private let tokenKey = "yap_apns_token"
    
    private init(api: APIClient = .init()) {
        self.api = api
    }
    
    // MARK: - APNs Token
    
    /// Called from AppDelegate when APNs returns a device token.
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        // Always sync token to server — ensures push_enabled is re-set to true
        // even if the server disabled it due to a BadDeviceToken error.
        Task { await registerDevice(apnsToken: token) }
    }
    
    /// Current APNs token (hex string), or nil if not yet registered.
    var apnsToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    /// Whether this device has registered for remote push.
    var isRegistered: Bool {
        apnsToken != nil
    }
    
    // MARK: - Device Registration
    
    /// Upsert device record in yap_devices.
    func registerDevice(apnsToken: String) async {
        do {
            try await api.restUpsert(
                table: "yap_devices",
                body: .json([
                    "device_id": APIClient.deviceId,
                    "apns_token": apnsToken,
                    "timezone": TimeZone.current.identifier,
                    "language": LanguageResolver.currentBackendLang(),
                    "push_enabled": true,
                    "is_simulator": AnalyticsService.isSimulator,
                ])
            )
            print("✅ Device registered for push (token: \(apnsToken.prefix(8))…)")
        } catch {
            print("⚠️ Device registration failed: \(error.localizedDescription)")
        }
    }
    
    /// Sync timezone, language & last_seen_at (call on app launch or settings change).
    func syncDeviceMetadata() async {
        guard isRegistered else { return }
        do {
            try await api.restUpdate(
                table: "yap_devices",
                query: "device_id=eq.\(APIClient.deviceId)",
                body: .json([
                    "timezone": TimeZone.current.identifier,
                    "language": LanguageResolver.currentBackendLang(),
                    "last_seen_at": ISO8601DateFormatter().string(from: Date()),
                ])
            )
        } catch {
            print("⚠️ Device metadata sync failed: \(error.localizedDescription)")
        }
    }
    
    /// Save which agent the user picked during onboarding.
    func saveOnboardingAgent(_ agent: String) async {
        do {
            try await api.restUpdate(
                table: "yap_devices",
                query: "device_id=eq.\(APIClient.deviceId)",
                body: .json(["onboarding_agent": agent])
            )
            print("✅ Onboarding agent saved: \(agent)")
        } catch {
            print("⚠️ Save onboarding agent failed: \(error.localizedDescription)")
        }
    }
    
    /// Lightweight touch — updates only last_seen_at (call on every foreground).
    func touchLastSeen() async {
        do {
            try await api.restUpdate(
                table: "yap_devices",
                query: "device_id=eq.\(APIClient.deviceId)",
                body: .json([
                    "last_seen_at": ISO8601DateFormatter().string(from: Date()),
                ])
            )
        } catch {
            print("⚠️ Touch last_seen failed: \(error.localizedDescription)")
        }
    }
    
    /// Disable push for this device (e.g. user turned off in settings).
    func disablePush() async {
        do {
            try await api.restUpdate(
                table: "yap_devices",
                query: "device_id=eq.\(APIClient.deviceId)",
                body: .json(["push_enabled": false])
            )
        } catch {
            print("⚠️ Disable push failed: \(error.localizedDescription)")
        }
    }
    
    /// Check if push is enabled on the server. If not, force re-register.
    /// Call this before creating a mission to ensure notifications will be delivered.
    func ensurePushEnabled() async {
        do {
            struct DeviceRow: Decodable {
                let pushEnabled: Bool
            }
            let rows: [DeviceRow] = try await api.rest(
                table: "yap_devices",
                query: "device_id=eq.\(APIClient.deviceId)&select=push_enabled"
            )
            if let row = rows.first, !row.pushEnabled {
                print("⚠️ Push was disabled server-side (BadDeviceToken?) — re-registering...")
                await forceReRegister()
            }
        } catch {
            print("⚠️ Push health check failed: \(error.localizedDescription)")
        }
    }
    
    /// Force re-register for remote notifications and upload token.
    func forceReRegister() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        // Also re-upload current token immediately with push_enabled: true
        if let token = apnsToken {
            await registerDevice(apnsToken: token)
        }
    }
    
    // MARK: - Notification Queries
    
    /// Fetch the body of the next pending notification for a goal.
    func fetchNextPendingMessage(goalId: UUID) async -> String? {
        struct PendingMessage: Decodable {
            let body: String
        }
        do {
            let msg: PendingMessage = try await api.rpc(
                function: "next_pending_message",
                params: .json(["p_goal_id": goalId.uuidString])
            )
            return msg.body
        } catch {
            return nil
        }
    }
    
    // MARK: - Cancel Pending (server-side)
    
    /// Cancel all pending remote notifications for a goal.
    func cancelPendingNotifications(goalId: UUID) async {
        do {
            let _: Int = try await api.rpc(
                function: "cancel_pending_notifications",
                params: .json(["p_goal_id": goalId.uuidString])
            )
        } catch {
            print("⚠️ Cancel pending notifications failed: \(error.localizedDescription)")
        }
    }
}
