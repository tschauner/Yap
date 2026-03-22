//
//  Mission+Stubs.swift
//  Yap
//
//  Created by Philipp Tschauner on 05.03.26.
//

import Foundation

extension Mission {
    static func dummy(_ agent: Agent = .mom) -> Self {
        Self(id: UUID(),
             deviceId: "someId",
             title: "Wäsche waschen",
             agent: agent,
             language: "de-DE",
             status: .active,
             createdAt: .now,
             deadline: .tomorrow,
             extended: false,
             notificationsScheduled: 20,
             notificationsSent: 1,
             isPro: false,
             usedAiCopy: true
        )
    }
    
    static func active(_ agent: Agent = .mom) -> Self {
        Self(id: UUID(),
             deviceId: "someId",
             title: "Wäsche waschen",
             agent: agent,
             language: "de-DE",
             status: .active,
             createdAt: .now,
             deadline: .tomorrow,
             extended: false,
             notificationsScheduled: 20,
             notificationsSent: 5,
             isPro: true,
             usedAiCopy: true
        )
    }
}
