//
//  CharactersResponseModel.swift
//  RickyBuggyBright
//

import Foundation

struct CharacterResponseModel: Decodable, Identifiable {
    
    let id: Int
    let name, status, species, type: String
    let gender: String
    let origin, location: Location
    let image: String
    let episode: [String]
    let url: String
    let created: String
    
    struct Location: Codable {
        let name: String
        let url: String
    }
}

extension CharacterResponseModel.Location {
    static let originDummy = CharacterResponseModel.Location(name: "Origin", url: "https://rickandmortyapi.com/api/location/1")
    static let dummy = CharacterResponseModel.Location(name: "Earth", url: "https://rickandmortyapi.com/api/location/3")
}

extension CharacterResponseModel {
    static let dummy = CharacterResponseModel(id: 1, name: "Jhonny", status: "Cash", species: "Human", type: "", gender: "Male", origin: .originDummy, location: .dummy, image: "https://rickandmortyapi.com/api/character/avatar/1.jpeg", episode: ["e1", "e2"], url: "https://rickandmortyapi.com/api/character/1", created: "2017-11-04T18:48:46.250Z")
}

