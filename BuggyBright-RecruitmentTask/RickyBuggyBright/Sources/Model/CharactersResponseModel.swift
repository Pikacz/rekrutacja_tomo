//
//  CharactersResponseModel.swift
//  RickyBuggyBright
//

import Foundation


struct CharacterDetailsResponseModel: Decodable, Identifiable {
    let character: CharacterResponseModel
    let details: String
    
    var id: Int {
        return character.id
    }
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.character = try container.decode(CharacterResponseModel.self)
        self.details = "At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat."
    }
}

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

