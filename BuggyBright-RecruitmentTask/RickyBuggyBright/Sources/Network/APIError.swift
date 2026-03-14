//
//  APIError.swift
//  RickyBuggyBright
//

import Foundation

// FIXME: 1 - Refactor so it accepts and displays underlaying error
enum APIError: Error {
    case imageDataRequestFailed
    case charactersRequestFailed
    case characterDetailRequestFailed
    case locationRequestFailed
}

extension APIError: LocalizedError {
    var localizedDescription: String {
        switch self {
        case .imageDataRequestFailed:
            return "Could not download image"
        case .charactersRequestFailed:
            return "Could not fetch characters"
        case .characterDetailRequestFailed:
            return "Could not get details of character"
        case .locationRequestFailed:
            return "Could not get details of location"
        }
    }
}
