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
        
        // Override title with agent display name (no emoji)
        let displayName = Self.agentDisplayName(for: agentKey)
        if !displayName.isEmpty {
            content.title = displayName
        }
        
        // Use Communication Notification (INSendMessageIntent) to show
        // the agent avatar on the LEFT side of the notification.
        
        let bundle = Bundle(for: NotificationService.self)
        let avatarImage = UIImage(named: agentKey, in: bundle, compatibleWith: nil)
        
                    if !agentKey.isEmpty,
                            let avatarImage,
                            let imageData = avatarImage.pngData() {
            logger.info("NSE avatar loaded for agent=\(agentKey, privacy: .public), bytes=\(imageData.count)")
            
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
                let updatedContent = try content.updating(from: intent)
                logger.info("NSE updating(from:) success for agent=\(agentKey, privacy: .public)")
                contentHandler(updatedContent)
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
}
