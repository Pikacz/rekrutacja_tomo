//
//  APIService.swift
//  RickyBuggyBright
//

import Foundation
import Combine
import UIKit

final class APIClient {
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
    
    
    
    func charactersPublisher() -> CharactersPublisher {

        return Just("/api/character/[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]")
            .setFailureType(to: Error.self)
            .flatMap(networkManager.publisher(path:))
            .decode(type: [CharacterResponseModel].self, decoder: JSONDecoder())
            .mapError { error in
                debugPrint(error)
                return APIError.charactersRequestFailed
            }
            .eraseToAnyPublisher()
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

// I want to be 100% sure that i do not block main thread by doing long task.
// At the moment I'm not aware of API that guarantes that…
private func ensureIsOnBackground<T>(work: @escaping () -> T) async -> T {
    guard Thread.isMainThread else {
        return work()
    }
    return await withUnsafeContinuation { continuation in
        DispatchQueue.global().async {
            continuation.resume(returning: work())
        }
    }
}
