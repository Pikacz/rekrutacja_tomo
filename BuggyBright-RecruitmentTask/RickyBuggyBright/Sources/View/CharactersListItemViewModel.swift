//
//  CharactersListItemViewModel.swift
//  RickyBuggyBright
//

import Combine
import Foundation
import UIKit

final class CharactersListItemViewModel: ObservableObject {

    @Published private(set) var characterErrors: [APIError] = []

    @Published private(set) var title: String = "-"
    @Published private(set) var created: String = "-"
    @Published private(set) var url: String = "-"
    @Published private(set) var imageUrl: URL? = nil

    private let characterSubject = CurrentValueSubject<CharacterResponseModel?, Never>(nil)

    private var cancellables = Set<AnyCancellable>()
    
    init(character: CharacterResponseModel) {
        // FIXME: Our usage of SwiftUI is CRAP. This init is called multiple times…
        print("🦕🦖 CharactersListItemViewModel.init \(character.id)")
        let apiService = DIContainer.shared.resolve(APIClient.self)
        let characterSharedPublisher = characterSubject
            .compactMap { $0 }
            .share()
        
        characterSharedPublisher
            .map(\.name)
            .assign(to: \.title, on: self)
            .store(in: &cancellables)
        
//        characterSharedPublisher.sink { characterModel in
//            Task.detached {
//                var image: UIImage? = nil
//                if let imageUrl = URL(string: characterModel.image), let apiService {
//                    let imageResult = await apiService.downloadImage(url: imageUrl)
//                    switch (imageResult) {
//                    case .success(let _image):
//                        image = _image
//                    case .failure:
//                        break
//                    }
//                }
//                DispatchQueue.main.async {
//                    self.characterImage = image
//                }
//            }
//        }.store(in: &cancellables)
        
        characterSharedPublisher
            .map {URL(string: $0.image) }
            .assign(to: \.imageUrl, on: self)
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
