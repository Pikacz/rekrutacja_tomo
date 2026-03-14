//
//  APIServiceProtocol.swift
//  RickyBuggyBright
//

import Foundation
import Combine

protocol APIProtocol {
    func imageDataPublisher(fromURLString urlString: String) -> ImageDataPublisher
    func charactersPublisher() -> CharactersPublisher
    func characterDetailPublisher(with id: String) -> CharacterDetailsPublisher
    func locationPublisher(with id: String) -> LocationPublisher
}

typealias ImageData = Data
typealias ImageDataPublisher = AnyPublisher<ImageData, APIError>
typealias CharactersPublisher = AnyPublisher<[CharacterResponseModel], APIError>
typealias CharacterDetailsPublisher = AnyPublisher<CharacterResponseModel, APIError>
typealias LocationPublisher = AnyPublisher<LocationDetailsResponseModel, APIError>
