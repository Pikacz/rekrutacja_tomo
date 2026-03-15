//
//  AppRepository.swift
//  RickyBuggyBright
//
//  Created by Paweł Czerwinski on 14/03/2026.
//

import Combine
import Foundation
import UIKit


@MainActor
final class CharacterDetailsModel {
    private let id: Int
    
    private let _lastListResponse = CurrentValueSubject<CharacterResponseModel?, Never>(nil)
    var lastListResponse: CharacterResponseModel? {
        return _lastListResponse.value
    }
    var lastListResponsePublisher: AnyPublisher<CharacterResponseModel?, Never> {
        return _lastListResponse.eraseToAnyPublisher()
    }
    
    private let _lastApiDetails = CurrentValueSubject<
        Result<CharacterDetailsResponseModel, ApiClientError>?,
        Never
    >(nil)
    var lastApiDetails: Result<CharacterDetailsResponseModel, ApiClientError>? {
        return _lastApiDetails.value
    }
    var lastApiDetailsPublisher: AnyPublisher<Result<CharacterDetailsResponseModel, ApiClientError>?, Never> {
        return _lastApiDetails.eraseToAnyPublisher()
    }
    
    private let _isDownloading = CurrentValueSubject<Bool, Never>(false)
    var isDownloading: Bool {
        return _isDownloading.value
    }
    var isDownloadingPublisher: AnyPublisher<Bool, Never> {
        return _isDownloading.eraseToAnyPublisher()
    }
    
    private var requestId = 0
    private let apiClient: APIClient
    
    init(character: CharacterResponseModel, apiClient: APIClient) {
        self.id = character.id
        _lastListResponse.value = character
        self.apiClient = apiClient
    }
    
    init(id: Int, apiClient: APIClient) {
        self.id = id
        self.apiClient = apiClient
    }
    
    func setListData(characterDetails: CharacterResponseModel) {
        _lastListResponse.value = characterDetails
    }
    
    func downloadIfNeeded() {
        guard !_isDownloading.value else { return }
        guard _lastApiDetails.value?._isSuccess != true else { return }
        _isDownloading.value = true
        requestId += 1
        let thisRequestId = requestId
        
        Task.detached {
            let result = await self.apiClient.downloadCharacterDetails(id: "\(self.id)")
            Task.detached { @MainActor in
                guard thisRequestId == self.requestId else { return }
                self._lastApiDetails.value = result
                self._isDownloading.value = false
            }
        }
    }
}


@MainActor
final class CharactersRepository {
    private var charactersCache: [Int: WeakReference<CharacterDetailsModel>] = [:]
    // All currently used `CharacterDetailsModel` would not be deallocated due to Swift's reference count.
    // By adding this trick some offscreen `CharacterDetailsModel` would be additionaly kept alive while ensuring that our cache
    // do not grow too much (max size of charactersCache is `number of CharacterDetailsModel in use + 30`)
    // On the other side we guarantee that only one `CharacterDetailsModel` exist for each id
    private let charactersLifetimeCache: NSCache<NSNumber, CharacterDetailsModel> = {
        let charactersLifetimeCache = NSCache<NSNumber, CharacterDetailsModel>()
        charactersLifetimeCache.countLimit = 30 // Randomly picked value that should make sense
        return charactersLifetimeCache
    }()
    private var tryClearCacheCounter = 0
    private let apiClient: APIClient
    
    private let _lastAllCharacters = CurrentValueSubject<
        Result<[CharacterResponseModel], ApiClientError>?,
        Never
    >(nil)
    private var _lastAllCharactersLifetime: [CharacterDetailsModel] = []
    
    var lastAllCharacters: Result<[CharacterResponseModel], ApiClientError>? {
        return _lastAllCharacters.value
    }
    var lastAllCharactersPublisher: AnyPublisher<Result<[CharacterResponseModel], ApiClientError>?, Never> {
        return _lastAllCharacters.eraseToAnyPublisher()
    }
    
    private let _isDownloadingAllCharacters = CurrentValueSubject<Bool, Never>(false)
    var isDownloadingAllCharacters: Bool {
        return _isDownloadingAllCharacters.value
    }
    var isDownloadingAllCharactersPublisher: AnyPublisher<Bool, Never> {
        return _isDownloadingAllCharacters.eraseToAnyPublisher()
    }
    private var requestId = 0
    
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    
    func downloadAllCharactersIfNeeded() {
        guard !_isDownloadingAllCharacters.value else { return }
        guard _lastAllCharacters.value?._isSuccess != true else { return }
        _isDownloadingAllCharacters.value = true
        requestId += 1
        let thisRequestId = requestId
        
        Task.detached {
            let result = await self.apiClient.downloadCharacters()
            Task.detached { @MainActor in
                switch result {
                case .success(let characters):
                    self.tryClearCacheCounter -= characters.count - 1 // we do not need to remove nil
                    self._lastAllCharactersLifetime = characters.map {
                        let details = self.getDetails(id: $0.id)
                        details.setListData(characterDetails: $0)
                        return details
                    }
                case .failure:
                    self._lastAllCharactersLifetime = []
                }
                
                guard thisRequestId == self.requestId else { return }
                self._lastAllCharacters.value = result
                self._isDownloadingAllCharacters.value = false
            }
        }
    }
    
    
    func getDetails(id: Int) -> CharacterDetailsModel {
        tryClearCacheCounter += 1
        if tryClearCacheCounter >= 60 { // Randomly picked value that should make sense
            removeDead(&charactersCache)
            tryClearCacheCounter = 0
        }
        
        let result = if let existing = charactersCache[id]?.value {
            existing
        } else {
            {
                let newInstance = CharacterDetailsModel(id: id, apiClient: apiClient)
                charactersCache[id] = WeakReference(value: newInstance)
                return newInstance
            }()
        }
        charactersLifetimeCache.setObject(result, forKey: NSNumber(value: id))
        return result
    }
}


@MainActor
final class LocationDetailsModel {
    private let url: URL
    
    private let _lastApiDetails = CurrentValueSubject<
        Result<LocationDetailsResponseModel, ApiClientError>?,
        Never
    >(nil)
    var lastApiDetails: Result<LocationDetailsResponseModel, ApiClientError>? {
        return _lastApiDetails.value
    }
    var lastApiDetailsPublisher: AnyPublisher<Result<LocationDetailsResponseModel, ApiClientError>?, Never> {
        return _lastApiDetails.eraseToAnyPublisher()
    }
    
    private let _isDownloading = CurrentValueSubject<Bool, Never>(false)
    var isDownloading: Bool {
        return _isDownloading.value
    }
    var isDownloadingPublisher: AnyPublisher<Bool, Never> {
        return _isDownloading.eraseToAnyPublisher()
    }
    
    private var requestId = 0
    private let apiClient: APIClient
    
    
    init(url: URL, apiClient: APIClient) {
        self.url = url
        self.apiClient = apiClient
    }
    
    func downloadIfNeeded() {
        guard !_isDownloading.value else { return }
        guard _lastApiDetails.value?._isSuccess != true else { return }
        _isDownloading.value = true
        requestId += 1
        let thisRequestId = requestId
        
        Task.detached {
            let result = await self.apiClient.downloadLocationDetails(url: self.url)
            Task.detached { @MainActor in
                guard thisRequestId == self.requestId else { return }
                self._lastApiDetails.value = result
                self._isDownloading.value = false
            }
        }
    }
}

@MainActor
final class LocationsRepository {
    private var locationsCache: [URL: WeakReference<LocationDetailsModel>] = [:]
    private let locationsLifetimeCache: NSCache<NSURL, LocationDetailsModel> = {
        let locationsLifetimeCache = NSCache<NSURL, LocationDetailsModel>()
        locationsLifetimeCache.countLimit = 30 // Randomly picked value that should make sense
        return locationsLifetimeCache
    }()
    private var tryClearCacheCounter = 0
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func getLocation(urlString: String) -> LocationDetailsModel? {
        guard let url = URL(string: urlString) else { return nil }
        return getLocation(url: url)
    }
    
    func getLocation(url: URL) -> LocationDetailsModel {
        tryClearCacheCounter += 1
        if tryClearCacheCounter >= 60 { // Randomly picked value that should make sense
            removeDead(&locationsCache)
            tryClearCacheCounter = 0
        }
        
        let result = if let existing = locationsCache[url]?.value {
            existing
        } else {
            {
                let newInstance = LocationDetailsModel(url: url, apiClient: apiClient)
                locationsCache[url] = WeakReference(value: newInstance)
                return newInstance
            }()
        }
        locationsLifetimeCache.setObject(result, forKey: url as NSURL)
        return result
    }
}


@MainActor
final class ImageModel {
    private let url: URL
    
    private let _lastApiDetails = CurrentValueSubject<
        Result<UIImage?, NetworkManagerError>?,
        Never
    >(nil)
    var lastApiDetails: Result<UIImage?, NetworkManagerError>? {
        return _lastApiDetails.value
    }
    var lastApiDetailsPublisher: AnyPublisher<Result<UIImage?, NetworkManagerError>?, Never> {
        return _lastApiDetails.eraseToAnyPublisher()
    }
    
    private let _isDownloading = CurrentValueSubject<Bool, Never>(false)
    var isDownloading: Bool {
        return _isDownloading.value
    }
    var isDownloadingPublisher: AnyPublisher<Bool, Never> {
        return _isDownloading.eraseToAnyPublisher()
    }
    
    private var requestId = 0
    private let apiClient: APIClient
    
    
    init(url: URL, apiClient: APIClient) {
        self.url = url
        self.apiClient = apiClient
    }
    
    func downloadIfNeeded() {
        guard !_isDownloading.value else { return }
        guard _lastApiDetails.value?._isSuccess != true else { return }
        _isDownloading.value = true
        requestId += 1
        let thisRequestId = requestId
        
        Task.detached {
            let result = await self.apiClient.downloadImage(url: self.url)
            Task.detached { @MainActor in
                guard thisRequestId == self.requestId else { return }
                self._lastApiDetails.value = result
                self._isDownloading.value = false
            }
        }
    }
}


@MainActor
final class ImagesRepository {
    private var imagesCache: [URL: WeakReference<ImageModel>] = [:]
    private let imagesLifetimeCache: NSCache<NSURL, ImageModel> = {
        let imagesLifetimeCache = NSCache<NSURL, ImageModel>()
        imagesLifetimeCache.countLimit = 30 // Randomly picked value that should make sense
        return imagesLifetimeCache
    }()
    private var tryClearCacheCounter = 0
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    
    func getOptionalImage(url: URL?) -> ImageModel? {
        guard let url else { return nil }
        return getImage(url: url)
    }
    
    func getImage(url: URL) -> ImageModel {
        tryClearCacheCounter += 1
        if tryClearCacheCounter >= 60 { // Randomly picked value that should make sense
            removeDead(&imagesCache)
            tryClearCacheCounter = 0
        }
        
        let result = if let existing = imagesCache[url]?.value {
            existing
        } else {
            {
                let newInstance = ImageModel(url: url, apiClient: apiClient)
                imagesCache[url] = WeakReference(value: newInstance)
                return newInstance
            }()
        }
        imagesLifetimeCache.setObject(result, forKey: url as NSURL)
        return result
    }
}


@MainActor
final class AppRepository {
    private let apiClient: APIClient
    
    let characters: CharactersRepository
    let locations: LocationsRepository
    let images: ImagesRepository
    
    init(
        baseUrl: String = "https://rickandmortyapi.com",
        networkManager: NetworkManager = NetworkManager(
            apiUrlSession: URLSession.shared,
            staticDataUrlSession: {
                // This code is suposed to aggresivly cache images
                let cache = URLCache(
                    memoryCapacity: 50 * 1024 * 1024, //  ~50 MB
                    diskCapacity: 200 * 1024 * 1024   // ~200 MB
                )
                let configuration = URLSessionConfiguration.default
                configuration.urlCache = cache
                configuration.requestCachePolicy = .returnCacheDataElseLoad
                return URLSession(configuration: configuration)
            }()
        )
    ) {
        self.apiClient = APIClient(
            baseUrl: baseUrl,
            networkManager: networkManager
        )
        
        self.characters = CharactersRepository(apiClient: apiClient)
        self.locations = LocationsRepository(apiClient: apiClient)
        self.images = ImagesRepository(apiClient: apiClient)
    }
    
    static let previewInstance = AppRepository(
        networkManager: createMockedServer()
    )
}


// Personally I would add #if DEBUG for previews
func createMockedServer() -> NetworkManager {
    MockedNetworkManager { request in
        switch request {
        case .charactersList:
            let result = "[{\"id\":1,\"name\":\"Rick Sanchez\",\"status\":\"Alive\",\"species\":\"Human\",\"type\":\"\",\"gender\":\"Male\",\"origin\":{\"name\":\"Earth (C-137)\",\"url\":\"https://rickandmortyapi.com/api/location/1\"},\"location\":{\"name\":\"Citadel of Ricks\",\"url\":\"https://rickandmortyapi.com/api/location/3\"},\"image\":\"https://rickandmortyapi.com/api/character/avatar/1.jpeg\",\"episode\":[\"https://rickandmortyapi.com/api/episode/1\",\"https://rickandmortyapi.com/api/episode/2\",\"https://rickandmortyapi.com/api/episode/3\",\"https://rickandmortyapi.com/api/episode/4\",\"https://rickandmortyapi.com/api/episode/5\",\"https://rickandmortyapi.com/api/episode/6\",\"https://rickandmortyapi.com/api/episode/7\",\"https://rickandmortyapi.com/api/episode/8\",\"https://rickandmortyapi.com/api/episode/9\",\"https://rickandmortyapi.com/api/episode/10\",\"https://rickandmortyapi.com/api/episode/11\",\"https://rickandmortyapi.com/api/episode/12\",\"https://rickandmortyapi.com/api/episode/13\",\"https://rickandmortyapi.com/api/episode/14\",\"https://rickandmortyapi.com/api/episode/15\",\"https://rickandmortyapi.com/api/episode/16\",\"https://rickandmortyapi.com/api/episode/17\",\"https://rickandmortyapi.com/api/episode/18\",\"https://rickandmortyapi.com/api/episode/19\",\"https://rickandmortyapi.com/api/episode/20\",\"https://rickandmortyapi.com/api/episode/21\",\"https://rickandmortyapi.com/api/episode/22\",\"https://rickandmortyapi.com/api/episode/23\",\"https://rickandmortyapi.com/api/episode/24\",\"https://rickandmortyapi.com/api/episode/25\",\"https://rickandmortyapi.com/api/episode/26\",\"https://rickandmortyapi.com/api/episode/27\",\"https://rickandmortyapi.com/api/episode/28\",\"https://rickandmortyapi.com/api/episode/29\",\"https://rickandmortyapi.com/api/episode/30\",\"https://rickandmortyapi.com/api/episode/31\",\"https://rickandmortyapi.com/api/episode/32\",\"https://rickandmortyapi.com/api/episode/33\",\"https://rickandmortyapi.com/api/episode/34\",\"https://rickandmortyapi.com/api/episode/35\",\"https://rickandmortyapi.com/api/episode/36\",\"https://rickandmortyapi.com/api/episode/37\",\"https://rickandmortyapi.com/api/episode/38\",\"https://rickandmortyapi.com/api/episode/39\",\"https://rickandmortyapi.com/api/episode/40\",\"https://rickandmortyapi.com/api/episode/41\",\"https://rickandmortyapi.com/api/episode/42\",\"https://rickandmortyapi.com/api/episode/43\",\"https://rickandmortyapi.com/api/episode/44\",\"https://rickandmortyapi.com/api/episode/45\",\"https://rickandmortyapi.com/api/episode/46\",\"https://rickandmortyapi.com/api/episode/47\",\"https://rickandmortyapi.com/api/episode/48\",\"https://rickandmortyapi.com/api/episode/49\",\"https://rickandmortyapi.com/api/episode/50\",\"https://rickandmortyapi.com/api/episode/51\"],\"url\":\"https://rickandmortyapi.com/api/character/1\",\"created\":\"2017-11-04T18:48:46.250Z\"}]".data(using: .utf8)!
            return .success((result, URLResponse()))
        case .characterDetails:
            let result = "{\"id\":1,\"name\":\"Rick Sanchez\",\"status\":\"Alive\",\"species\":\"Human\",\"type\":\"\",\"gender\":\"Male\",\"origin\":{\"name\":\"Earth (C-137)\",\"url\":\"https://rickandmortyapi.com/api/location/1\"},\"location\":{\"name\":\"Citadel of Ricks\",\"url\":\"https://rickandmortyapi.com/api/location/3\"},\"image\":\"https://rickandmortyapi.com/api/character/avatar/1.jpeg\",\"episode\":[\"https://rickandmortyapi.com/api/episode/1\",\"https://rickandmortyapi.com/api/episode/2\",\"https://rickandmortyapi.com/api/episode/3\",\"https://rickandmortyapi.com/api/episode/4\",\"https://rickandmortyapi.com/api/episode/5\",\"https://rickandmortyapi.com/api/episode/6\",\"https://rickandmortyapi.com/api/episode/7\",\"https://rickandmortyapi.com/api/episode/8\",\"https://rickandmortyapi.com/api/episode/9\",\"https://rickandmortyapi.com/api/episode/10\",\"https://rickandmortyapi.com/api/episode/11\",\"https://rickandmortyapi.com/api/episode/12\",\"https://rickandmortyapi.com/api/episode/13\",\"https://rickandmortyapi.com/api/episode/14\",\"https://rickandmortyapi.com/api/episode/15\",\"https://rickandmortyapi.com/api/episode/16\",\"https://rickandmortyapi.com/api/episode/17\",\"https://rickandmortyapi.com/api/episode/18\",\"https://rickandmortyapi.com/api/episode/19\",\"https://rickandmortyapi.com/api/episode/20\",\"https://rickandmortyapi.com/api/episode/21\",\"https://rickandmortyapi.com/api/episode/22\",\"https://rickandmortyapi.com/api/episode/23\",\"https://rickandmortyapi.com/api/episode/24\",\"https://rickandmortyapi.com/api/episode/25\",\"https://rickandmortyapi.com/api/episode/26\",\"https://rickandmortyapi.com/api/episode/27\",\"https://rickandmortyapi.com/api/episode/28\",\"https://rickandmortyapi.com/api/episode/29\",\"https://rickandmortyapi.com/api/episode/30\",\"https://rickandmortyapi.com/api/episode/31\",\"https://rickandmortyapi.com/api/episode/32\",\"https://rickandmortyapi.com/api/episode/33\",\"https://rickandmortyapi.com/api/episode/34\",\"https://rickandmortyapi.com/api/episode/35\",\"https://rickandmortyapi.com/api/episode/36\",\"https://rickandmortyapi.com/api/episode/37\",\"https://rickandmortyapi.com/api/episode/38\",\"https://rickandmortyapi.com/api/episode/39\",\"https://rickandmortyapi.com/api/episode/40\",\"https://rickandmortyapi.com/api/episode/41\",\"https://rickandmortyapi.com/api/episode/42\",\"https://rickandmortyapi.com/api/episode/43\",\"https://rickandmortyapi.com/api/episode/44\",\"https://rickandmortyapi.com/api/episode/45\",\"https://rickandmortyapi.com/api/episode/46\",\"https://rickandmortyapi.com/api/episode/47\",\"https://rickandmortyapi.com/api/episode/48\",\"https://rickandmortyapi.com/api/episode/49\",\"https://rickandmortyapi.com/api/episode/50\",\"https://rickandmortyapi.com/api/episode/51\"],\"url\":\"https://rickandmortyapi.com/api/character/1\",\"created\":\"2017-11-04T18:48:46.250Z\"}".data(using: .utf8)!
            return .success((result, URLResponse()))
        case .unknown:
            let result = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGNkYPjPwMDAxMDAwMDAAAALHwEDmIWXfgAAAABJRU5ErkJggg==")!
            return .success((result, URLResponse()))
            
        case .uselessFailingRequest:
            return .failure(.noNetworkAccess(genericError: nil))
        case .location:
            let result = "{\"id\":3,\"name\":\"Citadel of Ricks\",\"type\":\"Space station\",\"dimension\":\"unknown\",\"residents\":[\"https://rickandmortyapi.com/api/character/8\",\"https://rickandmortyapi.com/api/character/14\",\"https://rickandmortyapi.com/api/character/15\",\"https://rickandmortyapi.com/api/character/18\",\"https://rickandmortyapi.com/api/character/21\",\"https://rickandmortyapi.com/api/character/22\",\"https://rickandmortyapi.com/api/character/27\",\"https://rickandmortyapi.com/api/character/42\",\"https://rickandmortyapi.com/api/character/43\",\"https://rickandmortyapi.com/api/character/44\",\"https://rickandmortyapi.com/api/character/48\",\"https://rickandmortyapi.com/api/character/53\",\"https://rickandmortyapi.com/api/character/56\",\"https://rickandmortyapi.com/api/character/61\",\"https://rickandmortyapi.com/api/character/69\",\"https://rickandmortyapi.com/api/character/72\",\"https://rickandmortyapi.com/api/character/73\",\"https://rickandmortyapi.com/api/character/74\",\"https://rickandmortyapi.com/api/character/77\",\"https://rickandmortyapi.com/api/character/78\",\"https://rickandmortyapi.com/api/character/85\",\"https://rickandmortyapi.com/api/character/86\",\"https://rickandmortyapi.com/api/character/95\",\"https://rickandmortyapi.com/api/character/118\",\"https://rickandmortyapi.com/api/character/119\",\"https://rickandmortyapi.com/api/character/123\",\"https://rickandmortyapi.com/api/character/135\",\"https://rickandmortyapi.com/api/character/143\",\"https://rickandmortyapi.com/api/character/152\",\"https://rickandmortyapi.com/api/character/164\",\"https://rickandmortyapi.com/api/character/165\",\"https://rickandmortyapi.com/api/character/187\",\"https://rickandmortyapi.com/api/character/200\",\"https://rickandmortyapi.com/api/character/206\",\"https://rickandmortyapi.com/api/character/209\",\"https://rickandmortyapi.com/api/character/220\",\"https://rickandmortyapi.com/api/character/229\",\"https://rickandmortyapi.com/api/character/231\",\"https://rickandmortyapi.com/api/character/235\",\"https://rickandmortyapi.com/api/character/267\",\"https://rickandmortyapi.com/api/character/278\",\"https://rickandmortyapi.com/api/character/281\",\"https://rickandmortyapi.com/api/character/283\",\"https://rickandmortyapi.com/api/character/284\",\"https://rickandmortyapi.com/api/character/285\",\"https://rickandmortyapi.com/api/character/286\",\"https://rickandmortyapi.com/api/character/287\",\"https://rickandmortyapi.com/api/character/288\",\"https://rickandmortyapi.com/api/character/289\",\"https://rickandmortyapi.com/api/character/291\",\"https://rickandmortyapi.com/api/character/295\",\"https://rickandmortyapi.com/api/character/298\",\"https://rickandmortyapi.com/api/character/299\",\"https://rickandmortyapi.com/api/character/322\",\"https://rickandmortyapi.com/api/character/325\",\"https://rickandmortyapi.com/api/character/328\",\"https://rickandmortyapi.com/api/character/330\",\"https://rickandmortyapi.com/api/character/345\",\"https://rickandmortyapi.com/api/character/359\",\"https://rickandmortyapi.com/api/character/366\",\"https://rickandmortyapi.com/api/character/378\",\"https://rickandmortyapi.com/api/character/385\",\"https://rickandmortyapi.com/api/character/392\",\"https://rickandmortyapi.com/api/character/461\",\"https://rickandmortyapi.com/api/character/462\",\"https://rickandmortyapi.com/api/character/463\",\"https://rickandmortyapi.com/api/character/464\",\"https://rickandmortyapi.com/api/character/465\",\"https://rickandmortyapi.com/api/character/466\",\"https://rickandmortyapi.com/api/character/472\",\"https://rickandmortyapi.com/api/character/473\",\"https://rickandmortyapi.com/api/character/474\",\"https://rickandmortyapi.com/api/character/475\",\"https://rickandmortyapi.com/api/character/476\",\"https://rickandmortyapi.com/api/character/477\",\"https://rickandmortyapi.com/api/character/478\",\"https://rickandmortyapi.com/api/character/479\",\"https://rickandmortyapi.com/api/character/480\",\"https://rickandmortyapi.com/api/character/481\",\"https://rickandmortyapi.com/api/character/482\",\"https://rickandmortyapi.com/api/character/483\",\"https://rickandmortyapi.com/api/character/484\",\"https://rickandmortyapi.com/api/character/485\",\"https://rickandmortyapi.com/api/character/486\",\"https://rickandmortyapi.com/api/character/487\",\"https://rickandmortyapi.com/api/character/488\",\"https://rickandmortyapi.com/api/character/489\",\"https://rickandmortyapi.com/api/character/2\",\"https://rickandmortyapi.com/api/character/1\",\"https://rickandmortyapi.com/api/character/801\",\"https://rickandmortyapi.com/api/character/802\",\"https://rickandmortyapi.com/api/character/803\",\"https://rickandmortyapi.com/api/character/804\",\"https://rickandmortyapi.com/api/character/805\",\"https://rickandmortyapi.com/api/character/806\",\"https://rickandmortyapi.com/api/character/810\",\"https://rickandmortyapi.com/api/character/811\",\"https://rickandmortyapi.com/api/character/812\",\"https://rickandmortyapi.com/api/character/819\",\"https://rickandmortyapi.com/api/character/820\",\"https://rickandmortyapi.com/api/character/818\"],\"url\":\"https://rickandmortyapi.com/api/location/3\",\"created\":\"2017-11-10T13:08:13.191Z\"}".data(using: .utf8)!
            return .success((result, URLResponse()))
        }
    }
}
