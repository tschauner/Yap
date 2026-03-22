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
        let previousToken = UserDefaults.standard.string(forKey: tokenKey)
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        // Only sync if token changed or never synced
        if token != previousToken {
            Task { await registerDevice(apnsToken: token) }
        }
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
                ])
            )
            print("✅ Device registered for push (token: \(apnsToken.prefix(8))…)")
        } catch {
            print("⚠️ Device registration failed: \(error.localizedDescription)")
        }
    }
    
    /// Sync timezone & language (call on app launch or settings change).
    func syncDeviceMetadata() async {
        guard isRegistered else { return }
        do {
            try await api.restUpdate(
                table: "yap_devices",
                query: "device_id=eq.\(APIClient.deviceId)",
                body: .json([
                    "timezone": TimeZone.current.identifier,
                    "language": LanguageResolver.currentBackendLang(),
                ])
            )
        } catch {
            print("⚠️ Device metadata sync failed: \(error.localizedDescription)")
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
