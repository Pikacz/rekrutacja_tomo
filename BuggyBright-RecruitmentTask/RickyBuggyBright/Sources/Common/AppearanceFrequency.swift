//
//  AppearanceFrequency.swift
//  RickyBuggyBright
//

import Foundation


/// Level selected based on number of appearances in the show, if character appeared 10 times or more - it's high, if 3 times or more - its medium, if 1 or lower - it's low
struct AppearanceFrequency {
    enum FrequencyType {
        case high, medium, low
    }
    
    let count: Int
    let type: FrequencyType
    
    init(count: Int) {
        self.count = count
        type = if count >= 10 {
            .high
        } else if count >= 3 {
            .medium
        } else {
            .low
        }
    }
    
    var popularity: String {
        switch type {
        case .high:
            return "So popular!"
        case .medium:
            return "Kind of popular"
        case .low:
            return "Meh"
        }
    }
}
