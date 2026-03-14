//
//  APIService.swift
//  RickyBuggyBright
//

import Foundation
import Combine
import UIKit

enum ApiClientError: Error {
    case networkError(error: NetworkManagerError)
    case unexpectedError
}

final class APIClient {
    private let baseUrl: String = "https://rickandmortyapi.com"
    private let networkManager: NetworkManager
    
    init() {
        // FIXME: This DI is convoluted
        self.networkManager = DIContainer.shared.resolve(NetworkManager.self)!
    }
    
    func downloadImage(
        url: URL
    ) async -> Result<UIImage?, NetworkManagerError> {
        let result = await networkManager.performStaticRequest(
            request: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        )
        return switch(result) {
        case .success(let (data, _)):
                .success(await ensureIsOnBackground { UIImage(data: data) })
        case .failure(let error):
                .failure(error)
        }
    }
    
    func downloadCharacters() async -> Result<[CharacterResponseModel], ApiClientError> {
        let request = URLRequest(
            url: URL(string: baseUrl + "/api/character/[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]")!
        )
        let result = await networkManager.performApiRequest(request: request)
        return switch(result) {
        case .success(let (data, _)):
            await ensureIsOnBackground {
                do {
                    return .success(try decode(request: request, data: data))
                } catch {
                    return .failure(.unexpectedError)
                }
            }
        case .failure(let error):
                .failure(.networkError(error: error))
        }
    }
    
    func characterDetailPublisher(with id: String) -> CharacterDetailsPublisher {

        return Just("/api/character/\(id)")
            .setFailureType(to: Error.self)
            .flatMap(networkManager.publisher(path:))
            .decode(type: CharacterResponseModel.self, decoder: JSONDecoder())
            .mapError { error in
                debugPrint(error)
                return APIError.characterDetailRequestFailed
            }
            .eraseToAnyPublisher()
    }
    
    func locationPublisher(with id: String) -> LocationPublisher {

        return Just("/api/location/\(id)")
            .setFailureType(to: Error.self)
            .flatMap(networkManager.publisher(path:))
            .decode(type: LocationDetailsResponseModel.self, decoder: JSONDecoder())
            .mapError { error in
                debugPrint(error)
                return APIError.locationRequestFailed
            }
            .eraseToAnyPublisher()
    }
}

private let jsonDecoder = JSONDecoder()
private func decode<T: Decodable>(
    request: URLRequest,
    data: Data
) throws -> T {
    let parsingStart = diagnosticsCheapToUseTime()
    do {
        let result = try jsonDecoder.decode(T.self, from: data)
        let elapsedMs = diagnosticsTimeToMiliseconds(diagnosticsCheapToUseTime() - parsingStart)
        diagnosticsAddBreadcrumb(message: "Parsing \(request.diagnosticDescription) succeded after \(elapsedMs) ms")
        return result
    } catch {
        let elapsedMs = diagnosticsTimeToMiliseconds(diagnosticsCheapToUseTime() - parsingStart)
        diagnosticsNonFatalError(
            message: "Parsing \(request.diagnosticDescription) failed after \(elapsedMs) ms\nError: \(error)",
            parameters: [
                "data": String(data: data, encoding: .utf8) ?? data.base64EncodedString(),
                "error": error
            ],
            crashOnDebug: true
        )
        throw error
    }
}

// If you use Thread.isMainThread in async function you would get warning
// yet if you do it in normal function everything is fine
// It's nice to know that Swift warnings are not just random heuristics, don't you think?
// (But seriously I think that Swift compiler is slow but great, definitly heven compared to Kotlin)
private func silence_isMainThread_warning() -> Bool {
    return Thread.isMainThread
}

// I want to be 100% sure that i do not block main thread by doing long task.
// At the moment I'm not aware of API that guarantes that…
private func ensureIsOnBackground<T>(work: @escaping () -> T) async -> T {
    guard silence_isMainThread_warning() else {
        return work()
    }
    return await withUnsafeContinuation { continuation in
        DispatchQueue.global().async {
            continuation.resume(returning: work())
        }
    }
}


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
