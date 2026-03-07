// APIClient.swift
// Yap

import Foundation
import UIKit

// MARK: - Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case httpError(Int, String)
    case decodingFailed(Error)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .httpError(let code, let msg): "HTTP \(code): \(msg)"
        case .decodingFailed(let err): "Decoding: \(err.localizedDescription)"
        case .noData: "No data"
        }
    }
}

enum HTTPMethod: String { case GET, POST, PATCH, DELETE }

enum RequestBody {
    case json([String: Any])
    case encodable(Encodable)
    case none
}

// MARK: - APIClient

struct APIClient: Sendable {
    private let baseURL: String
    private let apiKey: String
    
    /// Persistent Device ID — stored in Keychain to survive app deletion.
    static let deviceId: String = {
        let keychainKey = "yap_device_id"
        let userDefaultsKey = "yap_device_id" // For migration
        
        // 1. Try Keychain first (survives app deletion)
        if let existing = KeychainHelper.read(forKey: keychainKey) {
            return existing
        }
        
        // 2. Migrate from UserDefaults (existing users)
        if let existing = UserDefaults.standard.string(forKey: userDefaultsKey) {
            _ = KeychainHelper.save(existing, forKey: keychainKey)
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            return existing
        }
        
        // 3. Create new ID
        let new = UUID().uuidString
        _ = KeychainHelper.save(new, forKey: keychainKey)
        return new
    }()
    
    init(baseURL: String = Config.supabaseURL, apiKey: String = Config.supabaseAnonKey) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - REST (Supabase PostgREST)
    
    func rest<T: Decodable>(
        table: String,
        query: String = "",
        timeout: TimeInterval = 10
    ) async throws -> T {
        let q = query.isEmpty ? "" : "?\(query)"
        return try await request(path: "/rest/v1/\(table)\(q)", method: .GET, timeout: timeout)
    }
    
    func restInsert<T: Decodable>(
        table: String,
        body: RequestBody,
        timeout: TimeInterval = 10
    ) async throws -> T {
        return try await request(
            path: "/rest/v1/\(table)",
            method: .POST,
            body: body,
            extraHeaders: ["Prefer": "return=representation"],
            timeout: timeout
        )
    }
    
    func restInsert(
        table: String,
        body: RequestBody,
        timeout: TimeInterval = 10
    ) async throws {
        let _ = try await rawRequest(
            path: "/rest/v1/\(table)",
            method: .POST,
            body: body,
            extraHeaders: ["Prefer": "return=minimal"],
            timeout: timeout
        )
    }
    
    func restUpdate<T: Decodable>(
        table: String,
        query: String,
        body: RequestBody,
        timeout: TimeInterval = 10
    ) async throws -> T {
        return try await request(
            path: "/rest/v1/\(table)?\(query)",
            method: .PATCH,
            body: body,
            extraHeaders: ["Prefer": "return=representation"],
            timeout: timeout
        )
    }
    
    func restUpdate(
        table: String,
        query: String,
        body: RequestBody,
        timeout: TimeInterval = 10
    ) async throws {
        let _ = try await rawRequest(
            path: "/rest/v1/\(table)?\(query)",
            method: .PATCH,
            body: body,
            extraHeaders: ["Prefer": "return=minimal"],
            timeout: timeout
        )
    }
    
    func restDelete(
        table: String,
        query: String,
        timeout: TimeInterval = 10
    ) async throws {
        let _ = try await rawRequest(
            path: "/rest/v1/\(table)?\(query)",
            method: .DELETE,
            timeout: timeout
        )
    }
    
    // MARK: - Edge Functions
    
    func edgeFunction<T: Decodable>(
        name: String,
        body: RequestBody = .none,
        timeout: TimeInterval = 30
    ) async throws -> T {
        return try await request(path: "/functions/v1/\(name)", method: .POST, body: body, timeout: timeout)
    }
    
    func edgeFunction(
        name: String,
        body: RequestBody = .none,
        timeout: TimeInterval = 30
    ) async throws -> Data {
        return try await rawRequest(path: "/functions/v1/\(name)", method: .POST, body: body, timeout: timeout)
    }
    
    // MARK: - RPC
    
    func rpc<T: Decodable>(
        function: String,
        params: RequestBody = .none,
        timeout: TimeInterval = 10
    ) async throws -> T {
        return try await request(path: "/rest/v1/rpc/\(function)", method: .POST, body: params, timeout: timeout)
    }
    
    // MARK: - Private
    
    private func request<T: Decodable>(
        path: String,
        method: HTTPMethod,
        body: RequestBody = .none,
        extraHeaders: [String: String] = [:],
        timeout: TimeInterval = 10
    ) async throws -> T {
        let data = try await rawRequest(path: path, method: method, body: body, extraHeaders: extraHeaders, timeout: timeout)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
    
    private func rawRequest(
        path: String,
        method: HTTPMethod,
        body: RequestBody = .none,
        extraHeaders: [String: String] = [:],
        timeout: TimeInterval = 10
    ) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.invalidURL }
        
        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.httpMethod = method.rawValue
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(Self.deviceId, forHTTPHeaderField: "x-device-id")
        extraHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        
        switch body {
        case .json(let dict):
            req.httpBody = try JSONSerialization.data(withJSONObject: dict)
        case .encodable(let value):
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .iso8601
            req.httpBody = try encoder.encode(value)
        case .none:
            break
        }
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.noData }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }
}
