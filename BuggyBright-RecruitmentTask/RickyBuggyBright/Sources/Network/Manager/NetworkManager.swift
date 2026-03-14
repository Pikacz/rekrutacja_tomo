//
//  NetworkManager.swift
//  RickyBuggyBright
//

import Foundation
import Combine

final class NetworkManager: NetworkManagerProtocol {
    
    static let RANDOM_HOST_NAME_TO_FAIL_REQUEST = "thisshouldfail.com"
    
    // FIXME: 2 - Refactor - add support for different properties eg. POST, httpBody, different timeouts etc.
    func publisher(path: String) -> Publishers.MapKeyPath<Publishers.MapError<URLSession.DataTaskPublisher, Error>, Data> {
        var components = URLComponents()
        components.scheme = "http"
        // This is inteded, if you decide to move this code around please keep functionallity to random fail request
        components.host = Int.random(in: 1...10) > 3 ? "rickandmortyapi.com" : NetworkManager.RANDOM_HOST_NAME_TO_FAIL_REQUEST
        components.path = path
        
        // FIXME: 3 - Add "guard let url = components.url else..."
        
        var request = URLRequest(url: components.url!, timeoutInterval: 5)
        request.httpMethod = "GET"

        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { $0 as Error }
            .map(\.data)
    }
    
    func publisher(fromURLString urlString: String) -> Publishers.MapError<Publishers.MapKeyPath<Publishers.FlatMap<URLSession.DataTaskPublisher, Publishers.ReceiveOn<Publishers.SetFailureType<Optional<URL>.Publisher, URLError>, DispatchQueue>>, Data>, Error> {
        return Just(urlString)
            .compactMap(URL.init)
            .setFailureType(to: URLError.self)
            .receive(on: DispatchQueue.main)
            .flatMap(URLSession.shared.dataTaskPublisher(for:))
            .map(\.data)
            .mapError { $0 as Error }
    }
}
