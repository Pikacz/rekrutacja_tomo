//
//  CharactersListItemViewModel.swift
//  RickyBuggyBright
//

import Combine
import Foundation

final class CharactersListItemViewModel: ObservableObject {

    @Published private(set) var characterErrors: [APIError] = []

    @Published private(set) var title: String = "-"
    @Published private(set) var characterImageData: Data?
    @Published private(set) var created: String = "-"
    @Published private(set) var url: String = "-"

    private let characterSubject = CurrentValueSubject<CharacterResponseModel?, Never>(nil)

    private var cancellables = Set<AnyCancellable>()
    
    init(character: CharacterResponseModel) {
        let apiService = DIContainer.shared.resolve(APIClient.self)
        let characterSharedPublisher = characterSubject
            .compactMap { $0 }
            .share()
        
        characterSharedPublisher
            .map(\.name)
            .assign(to: \.title, on: self)
            .store(in: &cancellables)
        
        characterSharedPublisher
            .map(\.image)
            .flatMap { imageURLString -> ImageDataPublisher in
                guard let apiService = apiService else {
                    return Empty().eraseToAnyPublisher()
                }
                return apiService.imageDataPublisher(fromURLString: imageURLString)
            }
            .replaceError(with: Data())
            .compactMap { $0 }
            .assign(to: \.characterImageData, on: self)
            .store(in: &cancellables)
        
        characterSharedPublisher
            .map(\.created)
            .removeDuplicates()
            .assign(to: \.created, on: self)
            .store(in: &cancellables)
        
        characterSharedPublisher
            .map(\.url)
            .removeDuplicates()
            .assign(to: \.url, on: self)
            .store(in: &cancellables)
        
        characterSubject.send(character)
    }
}
