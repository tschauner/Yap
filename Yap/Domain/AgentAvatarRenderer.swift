// AgentAvatarRenderer.swift
// Yap
//
// Renders agent avatar images (colored circle + emoji) for Communication Notifications.
// Uses UIGraphicsImageRenderer to create crisp circular avatars at runtime.

import SwiftUI

enum AgentAvatarRenderer {
    
    /// Cached avatars to avoid re-rendering for repeated notifications.
    private static var cache: [Agent: UIImage] = [:]
    
    /// Renders a circular avatar for the given agent.
    /// - Parameters:
    ///   - agent: The agent to render an avatar for.
    ///   - size: The diameter of the avatar (default: 300 for Retina).
    /// - Returns: A UIImage of the agent's colored circle with their emoji.
    static func avatar(for agent: Agent, size: CGFloat = 300) -> UIImage {
        if let cached = cache[agent] { return cached }
        
        // Debug: minimal avatar — just a solid colored circle
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            let cgContext = context.cgContext
            
            // Simple filled circle with agent color
            let color = UIColor(agent.accentColor)
            cgContext.setFillColor(color.cgColor)
            cgContext.fillEllipse(in: rect)
        }
        
        cache[agent] = image
        return image
    }
    
    /// Clears the avatar cache (e.g. on memory warning).
    static func clearCache() {
        cache.removeAll()
    }
}
