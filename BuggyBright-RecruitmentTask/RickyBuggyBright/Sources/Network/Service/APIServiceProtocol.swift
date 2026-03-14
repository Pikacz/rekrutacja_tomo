//
//  APIServiceProtocol.swift
//  RickyBuggyBright
//

import Foundation
import Combine

typealias ImageData = Data
typealias ImageDataPublisher = AnyPublisher<ImageData, APIError>
typealias CharactersPublisher = AnyPublisher<[CharacterResponseModel], APIError>
typealias CharacterDetailsPublisher = AnyPublisher<CharacterResponseModel, APIError>
typealias LocationPublisher = AnyPublisher<LocationDetailsResponseModel, APIError>
