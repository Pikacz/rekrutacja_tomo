//
//  NetworkManagerProtocol.swift
//  RickyBuggyBright
//

import Foundation
import Combine

protocol NetworkManagerProtocol {
    func publisher(path: String) -> Publishers.MapKeyPath<Publishers.MapError<URLSession.DataTaskPublisher, Error>, Data>
    func publisher(fromURLString urlString: String) -> Publishers.MapError<Publishers.MapKeyPath<Publishers.FlatMap<URLSession.DataTaskPublisher, Publishers.ReceiveOn<Publishers.SetFailureType<Optional<URL>.Publisher, URLError>, DispatchQueue>>, Data>, Error> 
}
