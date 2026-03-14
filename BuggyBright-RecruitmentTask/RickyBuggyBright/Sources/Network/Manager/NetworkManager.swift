//
//  NetworkManager.swift
//  RickyBuggyBright
//

import Foundation
import Combine




enum NetworkManagerError: Swift.Error {
    case networkingError
}


final class NetworkManager {
    
    private let apiUrlSession = URLSession.shared
    private let staticDataUrlSession = {
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, //  ~50 MB
            diskCapacity: 200 * 1024 * 1024   // ~200 MB
        )
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }()
    
    
    
    
    
    static let RANDOM_HOST_NAME_TO_FAIL_REQUEST = "thisshouldfail.com"
    
    // FIXME: 2 - Refactor - add support for different properties eg. POST, httpBody, different timeouts etc.
    func publisher(path: String) -> Publishers.MapKeyPath<Publishers.MapError<URLSession.DataTaskPublisher, Error>, Data> {
        var components = URLComponents()
        components.scheme = "https"
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
    
    
    func performApiRequest(request: URLRequest) async -> Result<(Data, URLResponse), NetworkManagerError> {
        return await Self.performRequest(
            urlSession: apiUrlSession,
            request: Int.random(in: 1...10) > 3 ? request : Self.RequestThatShouldFail
        )
    }
    
    func performStaticRequest(request: URLRequest) async -> Result<(Data, URLResponse), NetworkManagerError> {
        return await Self.performRequest(
            urlSession: staticDataUrlSession, request: request
        )
    }
    
    static func createRequest(
        path: String,
        httpMethod: String = "GET",
        httpBody: Data? = nil,
        timeoutInterval: TimeInterval = 5.0
    ) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "rickandmortyapi.com"
        components.path = path
        var request = URLRequest(url: components.url!, timeoutInterval: timeoutInterval)
        request.httpMethod = httpMethod
        request.httpBody = httpBody
        return request
    }
    
    private static func performRequest(
        urlSession: URLSession,
        request: URLRequest
    ) async -> Result<(Data, URLResponse), NetworkManagerError> {
        diagnosticsAddBreadcrumb(message: "Starting \(request.diagnosticDescription)")
        let requestStart = diagnosticsCheapToUseTime()
        do {
            let result = try await urlSession.data(for: request)
            let elapsedMs = diagnosticsTimeToMiliseconds(diagnosticsCheapToUseTime() - requestStart)
            diagnosticsAddBreadcrumb(message: "Request \(request.diagnosticDescription) succeded after \(elapsedMs) ms")
            return .success(result)
        } catch {
            let elapsedMs = diagnosticsTimeToMiliseconds(diagnosticsCheapToUseTime() - requestStart)
            diagnosticsAddBreadcrumb(
                message: "Request \(request.diagnosticDescription) failed after \(elapsedMs) ms",
                parameters: [
                    "error": error
                ]
            )
            // FIXME: check what errors are equivalent to noInternetConnection
            return .failure(NetworkManagerError.networkingError)
        }
    }
    
    private static let RequestThatShouldFail: URLRequest = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "thisshouldfail.com"
        components.path = "/whatever"
        var request = URLRequest(url: components.url!, timeoutInterval: 5.0)
        request.httpMethod = "GET"
        return request
    }()
}


private extension URLRequest {
    var diagnosticDescription: String {
        return url?.absoluteString ?? "--- we do not have url WTF bro? ---"
    }
}
