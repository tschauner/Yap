// NotificationService.swift
// YapNotificationService
//
// Notification Service Extension — uses Communication Notifications
// (INSendMessageIntent) to show the agent avatar on the LEFT side
// of the push notification, like messaging apps.

import UserNotifications
import UIKit
import Intents
import OSLog

class NotificationService: UNNotificationServiceExtension {
    private let logger = Logger(subsystem: "com.phitsch.Yap", category: "NotificationService")
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let content = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        
        // Get and normalize agent key from payload (supports legacy values)
        let rawAgentKey = request.content.userInfo["agent"] as? String ?? ""
        let agentKey = Self.normalizeAgentKey(rawAgentKey)
        logger.info("NSE rawAgent=\(rawAgentKey, privacy: .public) normalizedAgent=\(agentKey, privacy: .public)")
        
        // Agent display name for Communication Notification sender
        let displayName = Self.agentDisplayName(for: agentKey)
        
        // Use Communication Notification (INSendMessageIntent) to show
        // the agent avatar on the LEFT side of the notification.
        
        // Render agent avatar dynamically (gradient circle + emoji) — no static assets needed.
        let avatarImage = Self.renderAgentAvatar(for: agentKey)
        
                    if !agentKey.isEmpty,
                            let avatarImage,
                            let imageData = avatarImage.pngData() {
            logger.info("NSE avatar rendered for agent=\(agentKey, privacy: .public), bytes=\(imageData.count)")
            
            let handle = INPersonHandle(value: "agent-\(agentKey)", type: .unknown)
                        let avatar = INImage(imageData: imageData)
            var components = PersonNameComponents()
            components.givenName = displayName
            
            let sender = INPerson(
                personHandle: handle,
                nameComponents: components,
                displayName: displayName.isEmpty ? "Yap" : displayName,
                image: avatar,
                contactIdentifier: nil,
                customIdentifier: agentKey,
                isMe: false,
                suggestionType: .none
            )
            let me = INPerson(
                personHandle: INPersonHandle(value: "me", type: .unknown),
                nameComponents: nil,
                displayName: "You",
                image: nil,
                contactIdentifier: nil,
                customIdentifier: "me",
                isMe: true,
                suggestionType: .none
            )
            
            let intent = INSendMessageIntent(
                recipients: [me],
                outgoingMessageType: .outgoingMessageText,
                content: content.body,
                speakableGroupName: nil,
                conversationIdentifier: agentKey,
                serviceName: "Yap",
                sender: sender,
                attachments: nil
            )
            intent.setImage(avatar, forParameterNamed: \INSendMessageIntent.sender)
            
            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming
            interaction.donate { error in
                if let error {
                    self.logger.error("Interaction donation failed: \(error.localizedDescription, privacy: .public)")
                }
            }
            
            do {
                let originalUserInfo = content.userInfo
                let updatedContent = try content.updating(from: intent)
                // Restore userInfo — updating(from:) can drop custom fields like goalId
                if let mutableUpdated = updatedContent.mutableCopy() as? UNMutableNotificationContent {
                    // Restore custom userInfo (goalId, level, agent) that may be lost
                    var mergedInfo = mutableUpdated.userInfo
                    for (key, value) in originalUserInfo {
                        if mergedInfo[key] == nil {
                            mergedInfo[key] = value
                        }
                    }
                    mutableUpdated.userInfo = mergedInfo
                    logger.info("NSE success for agent=\(agentKey, privacy: .public)")
                    contentHandler(mutableUpdated)
                } else {
                    contentHandler(updatedContent)
                }
                return
            } catch {
                logger.error("Communication Notification failed: \(error.localizedDescription, privacy: .public)")
                // intent failed, fall through to plain delivery
            }
        } else {
            logger.error("NSE avatar missing for agent=\(agentKey, privacy: .public). Check asset name + target membership.")
            // no avatar available, fall through to plain delivery
        }
        
        // Fallback: deliver with title override but no avatar
        contentHandler(content)
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let content = bestAttemptContent {
            contentHandler(content)
        }
    }

    // MARK: - Agent Mapping

    private static func normalizeAgentKey(_ key: String) -> String {
        switch key {
        case "Best Friend", "best friend": return "bestFriend"
        case "Mom", "mom": return "mom"
        case "Boss", "boss": return "boss"
        case "Drill Sergeant", "drill sergeant": return "drill"
        case "Therapist", "therapist": return "therapist"
        case "Grandma", "grandma": return "grandma"
        case "The Ex", "ex": return "ex"
        case "The Theorist", "conspiracy theorist": return "conspiracyTheorist"
        case "The Colleague", "passive aggressive colleague": return "passiveAggressiveColleague"
        case "The Chef", "the chef", "Gordon Ramsay", "gordon ramsay": return "chef"
        case "Disappointed Dad", "disappointed dad": return "disappointedDad"
        case "Gym Bro", "gym bro": return "gymBro"
        default: return key
        }
    }
    
    private static func agentDisplayName(for key: String) -> String {
        switch key {
        case "bestFriend": return "Best Friend"
        case "mom": return "Mom"
        case "boss": return "Boss"
        case "drill": return "Drill Sergeant"
        case "therapist": return "Therapist"
        case "grandma": return "Grandma"
        case "ex": return "The Ex"
        case "conspiracyTheorist": return "The Theorist"
        case "passiveAggressiveColleague": return "The Colleague"
        case "chef", "gordonRamsay": return "The Chef"
        case "disappointedDad": return "Disappointed Dad"
        case "gymBro": return "Gym Bro"
        default: return ""
        }
    }
    
    // MARK: - Avatar Renderer
    
    /// Renders a gradient circle with emoji — matches AgentCircle in the app.
    /// Diagonal gradient: lighter (top-right) → base color (bottom-left).
    private static func renderAgentAvatar(for agentKey: String, size: CGFloat = 300) -> UIImage? {
        guard let baseColor = agentAccentColor(for: agentKey) else { return nil }
        let emoji = agentEmoji(for: agentKey)
        
        // Gradient: lighter shade (top-right) → base color (bottom-left)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        baseColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let lighterColor = UIColor(hue: h, saturation: max(s * 0.7, 0.0), brightness: min(b * 1.35, 1.0), alpha: a)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            let cgContext = context.cgContext
            
            // Clip to circle
            cgContext.addEllipse(in: rect)
            cgContext.clip()
            
            // Draw diagonal gradient: lighter top-right → base bottom-left
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let cgColors = [lighterColor.cgColor, baseColor.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: [0.0, 1.0]) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: size, y: 0),
                    end: CGPoint(x: 0, y: size),
                    options: []
                )
            }
            
            // Draw emoji centered — use 65% of circle size (matches app: 40pt emoji in 60pt circle)
            let emojiFont = UIFont.systemFont(ofSize: size * 0.65)
            let attributes: [NSAttributedString.Key: Any] = [.font: emojiFont]
            let attrString = NSAttributedString(string: emoji, attributes: attributes)
            let boundingRect = attrString.boundingRect(
                with: CGSize(width: size, height: size),
                options: [.usesLineFragmentOrigin],
                context: nil
            )
            let emojiOrigin = CGPoint(
                x: (size - boundingRect.width) / 2 - boundingRect.origin.x,
                y: (size - boundingRect.height) / 2 - boundingRect.origin.y
            )
            attrString.draw(at: emojiOrigin)
        }
    }
    
    /// Accent color per agent — matches Agent.accentColor in the main app exactly.
    private static func agentAccentColor(for key: String) -> UIColor? {
        switch key {
        case "bestFriend":     return .systemBlue
        case "mom":            return .systemPink
        case "boss":           return .systemGray
        case "drill":          return .systemGreen
        case "therapist":      return .systemPurple
        case "grandma":        return UIColor(red: 0.85, green: 0.55, blue: 0.45, alpha: 1)
        case "ex":             return UIColor(red: 0.8, green: 0.2, blue: 0.4, alpha: 1)
        case "conspiracyTheorist": return UIColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1)
        case "passiveAggressiveColleague": return .systemGray2
        case "chef":           return UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1)
        case "disappointedDad": return UIColor(red: 0.5, green: 0.38, blue: 0.25, alpha: 1)
        case "gymBro":         return .systemOrange
        default:               return nil
        }
    }
    
    /// Emoji per agent — matches Agent.emoji in the main app.
    private static func agentEmoji(for key: String) -> String {
        switch key {
        case "bestFriend": return "🫶"
        case "mom": return "🫵"
        case "boss": return "👔"
        case "drill": return "🪖"
        case "therapist": return "🛋️"
        case "grandma": return "👵"
        case "ex": return "💔"
        case "conspiracyTheorist": return "🛸"
        case "passiveAggressiveColleague": return "🙂"
        case "chef": return "👨‍🍳"
        case "disappointedDad": return "🤦"
        case "gymBro": return "💪"
        default: return "📢"
        }
    }
}
