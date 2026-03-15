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
    static let shared = AppRepository()
    
    private let apiClient: APIClient = APIClient()
    
    let characters: CharactersRepository
    let locations: LocationsRepository
    let images: ImagesRepository
    
    init() {
        self.characters = CharactersRepository(apiClient: apiClient)
        self.locations = LocationsRepository(apiClient: apiClient)
        self.images = ImagesRepository(apiClient: apiClient)
    }
    
}
