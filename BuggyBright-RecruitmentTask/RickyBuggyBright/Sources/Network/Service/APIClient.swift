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


final class APIClient: Sendable {
    private let baseUrl: String = "https://rickandmortyapi.com"
    private let networkManager: NetworkManager
    
    init() {
        // FIXME: This DI is convoluted
        self.networkManager = DIContainer.shared.resolve(NetworkManager.self)!
    }
    
    func downloadImage(
        url: URL
    ) async -> Result<UIImage?, NetworkManagerError> {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let result = await networkManager.performStaticRequest(
            request: request
        )
        return switch(result) {
        case .success(let (data, _)):
                .success(await ensureIsOnBackground {
                    let parsingStart = diagnosticsCheapToUseTime()
                    let result = UIImage(data: data)
                    let elapsedMs = diagnosticsTimeToMiliseconds(diagnosticsCheapToUseTime() - parsingStart)
                    
                    diagnosticsAddBreadcrumb(message: "Request \(request.diagnosticDescription) parsed image in \(elapsedMs) ms")
                    return result
                })
        case .failure(let error):
                .failure(error)
        }
    }
    
    func downloadCharacters() async -> Result<[CharacterResponseModel], ApiClientError> {
        return await downloadAndParse(
            request: URLRequest(
                url: URL(string: baseUrl + "/api/character/[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]")!
            )
        )
    }
    
    func downloadCharacterDetails(id: String) async -> Result<CharacterDetailsResponseModel, ApiClientError> {
        return await downloadAndParse(
            request: URLRequest(
                url: URL(string: baseUrl + "/api/character/\(id)")!
            )
        )
    }
    
    func locationDetailsUrl(id: String) -> URL {
        return URL(string: baseUrl + "/api/location/\(id)")!
    }
    
    func downloadLocationDetails(url: URL) async -> Result<LocationDetailsResponseModel, ApiClientError> {
        return await downloadAndParse(request: URLRequest(url: url))
    }
    
    private func downloadAndParse<T: Decodable>(request: URLRequest) async -> Result<T, ApiClientError> {
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
}


private let jsonDecoder = JSONDecoder()
private func decode<T: Decodable>(
    request: URLRequest,
    data: Data
) throws -> T {
    let parsingStart = diagnosticsCheapToUseTime()
//    #if DEBUG
//    if let text = String(data: data, encoding: .utf8) {
//        print(text)
//    }
//    #endif
    
    do {
        let result = try jsonDecoder.decode(T.self, from: data)
        let elapsedMs = diagnosticsTimeToMiliseconds(diagnosticsCheapToUseTime() - parsingStart)
        diagnosticsAddBreadcrumb(message: "Request \(request.diagnosticDescription) parsed after \(elapsedMs) ms")
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


// NOTE: This mapping was written in 15 minutes.
// It probably require more research
enum NetworkManagerError: Error {
    // User disabled interent -> prompt to enable internet
    case internetDisabled
    // For example WI-FI have no acces to internet -> prompt to check other network
    case noNetworkAccess
    // Something happened (most likely timeout) -> prompt to try again later
    case otherNetworkingError
}


final class NetworkManager: Sendable {
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
    
    private static func performRequest(
        urlSession: URLSession,
        request: URLRequest
    ) async -> Result<(Data, URLResponse), NetworkManagerError> {
        diagnosticsAddBreadcrumb(message: "Starting \(request.diagnosticDescription)")
        let requestStart = diagnosticsCheapToUseTime()
        do {
            let result = try await urlSession.data(for: request)
            let elapsedMs = diagnosticsTimeToMiliseconds(diagnosticsCheapToUseTime() - requestStart)
            diagnosticsAddBreadcrumb(message: "Request \(request.diagnosticDescription) downloaded after \(elapsedMs) ms")
            return .success(result)
        } catch {
            
            let parsedError: NetworkManagerError
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .internationalRoamingOff, .dataNotAllowed:
                    parsedError = .internetDisabled
                case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .networkConnectionLost:
                    parsedError = .noNetworkAccess
                default:
                    parsedError = .otherNetworkingError
                }
            } else {
                parsedError = .otherNetworkingError
            }
            
            let elapsedMs = diagnosticsTimeToMiliseconds(diagnosticsCheapToUseTime() - requestStart)
            diagnosticsAddBreadcrumb(
                message: "Request \(request.diagnosticDescription) failed after \(elapsedMs) ms",
                parameters: [
                    "error": error,
                    "parsedError": "\(parsedError)"
                ]
            )
            return .failure(parsedError)
            
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
