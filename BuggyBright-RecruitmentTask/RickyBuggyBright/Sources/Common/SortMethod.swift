//
//  SortMethod.swift
//  RickyBuggyBright
//

// FIXME: 5 - Fix sorting, so it works - and sorts downloaded characters
enum SortMethod: Int {
    case name
    case episodesCount
}

extension SortMethod: CustomStringConvertible {
    var description: String {
        switch self {
        case .name:
            return "Name"
        case .episodesCount:
            return "Episodes Count"
        }
    }
}
