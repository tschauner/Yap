// SystemImage.swift
// Yap

import SwiftUI

enum SystemImage: String {
    // Personas
    case personTwo = "person.2.fill"
    case heart = "heart.fill"
    case briefcase = "briefcase.fill"
    case shield = "shield.fill"
    case brain = "brain.head.profile"
    case eyeglasses
    case eye = "eye.slash"
    case ellipsis
    case personPlus = "person.badge.plus"
    case agent = "person.wave.2"
    case wave = "wave.3.forward"
    
    // Navigation
    case chevronRight = "chevron.right"
    case chevronLeft = "chevron.backward"
    case close = "xmark"
    case closeFill = "xmark.circle.fill"
    
    // Actions
    case checkmark
    case checkmarkCircle = "checkmark.circle.fill"
    case timer = "clock.arrow.2.circlepath"
    case clock
    case bell
    case bellSlash = "bell.slash"
    case flame = "flame"
    case flag = "flag.pattern.checkered"
    
    // Status
    case info = "info.circle"
    case lock = "lock.fill"
    case starFilled = "star.fill"
    case star
    case sparkles
    
    case paperplane
    case plus
    case moon
    case sun = "sun.max"
    case archive = "archivebox"
    case bag = "case"
    case bagFill = "case.fill"
    case lightBulb = "lightbulb.max"
    case popcorn
    case hexagon
    case link
    case appBadge = "app.badge.fill"
    case medal = "medal.star"
    case quoteOpening = "quote.opening"
    case quoteClosing = "quote.closing"
    case laurelLeading = "laurel.leading"
    case laurelTrailing = "laurel.trailing"
}

extension Image {
    init(icon: SystemImage) {
        self.init(systemName: icon.rawValue)
    }
}
