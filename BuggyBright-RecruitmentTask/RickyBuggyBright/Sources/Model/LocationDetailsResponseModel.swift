//
//  LocationDetailsResponseModel.swift
//  RickyBuggyBright
//

import Foundation

struct LocationDetailsResponseModel: Decodable, Identifiable {
    let id: Int
    let name, type, dimension: String
    let residents: [String]
    let url: String
    let created: String
}

extension LocationDetailsResponseModel {
    static let dummy = LocationDetailsResponseModel(id: 3, name: "Citadel", type: "Space station", dimension: "unknown", residents: [ "https://rickandmortyapi.com/api/character/8","https://rickandmortyapi.com/api/character/14"], url: "https://rickandmortyapi.com/api/location/3", created: "2017-11-10T13:08:13.191Z")
}
