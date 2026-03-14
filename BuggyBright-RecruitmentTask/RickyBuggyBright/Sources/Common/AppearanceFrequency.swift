//
//  AppearanceFrequency.swift
//  RickyBuggyBright
//

import Foundation


/// Level selected based on number of appearances in the show, if character appeared 10 times or more - it's high, if 3 times or more - its medium, if 1 or lower - it's low
enum AppearanceFrequency: Int {
    case high = 10
    case medium = 3
    case low = 1
}

// FIXME: 4 - Fix issue with initialisation not working accordingly to requirements written above, try improving clean code approach

extension AppearanceFrequency {
    init(count: Int) {
        if count >= 1 {
            self = .low
        } else if count >= 3 {
            self = .medium
        } else {
            self = .high
        }
    }
    
    var popularity: String {
        switch self {
        case .high:
            return "So popular!"
        case .medium:
            return "Kind of popular"
        case .low:
            return "Meh"
        }
    }
}
