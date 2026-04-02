// AuthService.swift
// Yap

import Foundation
import AuthenticationServices
import Combine
import UserNotifications

/// Manages Apple Sign-In and device linking.
@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published var isLinked: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let appleUserKey = "yap_apple_user_id"
    private let api = APIClient()
    
    var appleUserId: String? {
        UserDefaults.standard.string(forKey: appleUserKey)
    }
    
    override init() {
        super.init()
        isLinked = appleUserId != nil
    }
    
    // MARK: - Sign In
    
    /// Called from SignInWithAppleButton's onCompletion handler.
    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                error = "Invalid credential"
                isLoading = false
                return
            }
            Task {
                await linkDevice(appleUserId: credential.user)
            }
        case .failure(let err):
            // User cancelled is not an error
            if (err as? ASAuthorizationError)?.code == .canceled {
                isLoading = false
                return
            }
            error = err.localizedDescription
            isLoading = false
        }
    }
    
    /// Legacy delegate-based sign in (keep for programmatic use).
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [] // We don't need email or name
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
        
        isLoading = true
        error = nil
    }
    
    // MARK: - Link Device
    
    private func linkDevice(appleUserId: String) async {
        do {
            let result: LinkResult = try await api.rpc(
                function: "link_apple_user",
                params: .json([
                    "p_apple_user_id": appleUserId,
                    "p_current_device_id": APIClient.deviceId
                ])
            )
            
            // Save Apple User ID locally
            UserDefaults.standard.set(appleUserId, forKey: appleUserKey)
            
            if result.migrated {
                // User logged in on new device — restore old device ID
                UserDefaults.standard.set(result.deviceId, forKey: "yap_device_id")
                print("✅ Restored device ID from Apple account: \(result.deviceId)")
            }
            
            isLinked = true
            isLoading = false
            
            print("✅ Apple Sign-In: \(result.status)")
            
        } catch {
            self.error = "Could not link account: \(error.localizedDescription)"
            isLoading = false
            print("⚠️ Link failed: \(error)")
        }
    }
    
    // MARK: - Unlink
    
    func unlinkAccount() async {
        guard let appleUserId = appleUserId else { return }
        
        isLoading = true
        
        do {
            let _: Bool = try await api.rpc(
                function: "unlink_apple_user",
                params: .json(["p_apple_user_id": appleUserId])
            )
            
            UserDefaults.standard.removeObject(forKey: appleUserKey)
            isLinked = false
            isLoading = false
            
            print("✅ Account unlinked")
            
        } catch {
            self.error = "Could not unlink: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Delete Account
    
    /// Deletes all server-side data and resets local state.
    func deleteAccount() async throws {
        isLoading = true
        
        do {
            // 1. Delete all server data via RPC
            let _: Bool = try await api.rpc(
                function: "delete_account",
                params: .json(["p_device_id": APIClient.deviceId])
            )
            
            // 2. Clear local Apple Sign-In state
            UserDefaults.standard.removeObject(forKey: appleUserKey)
            isLinked = false
            
            // 3. Clear all UserDefaults (keep Keychain/device ID to prevent abuse)
            if let bundleId = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleId)
            }
            
            // 5. Remove pending notifications
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
            isLoading = false
            print("✅ Account deleted")
            
        } catch {
            self.error = "Could not delete account: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }
        
        let userId = credential.user
        
        Task { @MainActor in
            await linkDevice(appleUserId: userId)
        }
    }
    
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
}

// MARK: - Link Result

private struct LinkResult: Decodable {
    let status: String
    let deviceId: String
    let migrated: Bool
}
