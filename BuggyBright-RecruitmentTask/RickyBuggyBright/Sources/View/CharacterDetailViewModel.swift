//
//  CharacterDetailViewModel.swift
//  RickyBuggyBright
//

import Combine
import Foundation
import UIKit

final class CharacterDetailViewModel: ObservableObject {
    @Published var showsLocationDetailsView = false

    @Published private(set) var data: (characterDetails: CharacterDetailsResponseModel, location: LocationDetailsResponseModel)?
    @Published private(set) var CharacterPhotoURL: URL?
    @Published private(set) var characterErrors: [ApiClientError] = []

    @Published private(set) var title: String = "-"
    @Published private(set) var popularityName: String = "-"
    @Published private(set) var url: String = "-"
    @Published private(set) var created: String = "-"
    
    @Published private(set) var details: String = "-"
    
    private let showsLocationDetailsSubject = CurrentValueSubject<Bool?, Never>(nil)

    private let characterIDSubject = CurrentValueSubject<Int?, Never>(nil)
    private let dataSubject = PassthroughSubject<(characterDetails: CharacterDetailsResponseModel, location: LocationDetailsResponseModel), Never>()

    private var isLoading = false
    private var cancellables = Set<AnyCancellable>()
    
    init(characterId: Int, name: String) {
        self.title = name

        let apiService = DIContainer.shared.resolve(APIClient.self)

        showsLocationDetailsSubject
            .compactMap { $0 }
            .removeDuplicates()
            .assign(to: \.showsLocationDetailsView, on: self)
            .store(in: &cancellables)

        let dataPublisher = dataSubject
            .compactMap { $0 }
            .share()

        let characterDetailsPublisher = dataPublisher
            .map(\.characterDetails)

        dataPublisher
            .sink(receiveValue: { [weak self] characterDetail, location in
                self?.data = (characterDetail, location)
            })
            .store(in: &cancellables)
        
        characterDetailsPublisher
            .map { URL(string: $0.character.image) }
            .assign(to: \.CharacterPhotoURL, on: self)
            .store(in: &cancellables)


        characterDetailsPublisher
            .map(\.character.name)
            .assign(to: \.title, on: self)
            .store(in: &cancellables)

        characterDetailsPublisher
            .map(\.character.episode)
            .map(\.count)
            .compactMap(AppearanceFrequency.init(count:))
            .map(\.popularity)
            .assign(to: \.popularityName, on: self)
            .store(in: &cancellables)
        
        characterDetailsPublisher
            .map(\.character.url)
            .removeDuplicates()
            .assign(to: \.url, on: self)
            .store(in: &cancellables)

        characterDetailsPublisher
            .map(\.character.created)
            .assign(to: \.created, on: self)
            .store(in: &cancellables)
        
        characterDetailsPublisher
            .map(\.details)
            .assign(to: \.details, on: self)
            .store(in: &cancellables)

        characterIDSubject.send(characterId)
    }
    
    // MARK: - Inputs

    func setShowsLocationDetails() {
        showsLocationDetailsSubject.send(true)
    }
    
    func requestData() {
        guard isLoading == false else { return }
        guard let characterID = characterIDSubject.value else { return }
        let apiService = DIContainer.shared.resolve(APIClient.self)!
        
        
        data = nil
        characterErrors.removeAll()
        isLoading = true
        
        Task.detached {
            let characterDetailsResponse = await apiService.downloadCharacterDetails(id: "\(characterID)")
            switch characterDetailsResponse {
            case .success(let characterDetails):
                // FIXME: 11 - FIX so location is fetched based on character location id
                let locationDetailsResponse = await apiService.downloadLocationDetails(id: "2")
                DispatchQueue.main.async {
                    switch locationDetailsResponse {
                    case .success(let locationDetails):
                        self.dataSubject.send((characterDetails, locationDetails))
                    case .failure(let error):
                        self.characterErrors.append(error)
                    }
                    self.isLoading = false
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.characterErrors.append(error)
                }
            }
            
        }
    }
}
