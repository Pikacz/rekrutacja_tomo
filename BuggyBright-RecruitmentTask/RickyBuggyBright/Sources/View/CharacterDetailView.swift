//
//  CharacterDetailView.swift
//  RickyBuggyBright
//

import Combine
import SwiftUI


@MainActor
final class CharacterDetailViewModel: ObservableObject {
    @Published var showsLocationDetailsView = false
    
    @Published private(set) var characterFromListDetails: CharacterResponseModel?
    @Published private(set) var characterDetails: CharacterDetailsResponseModel?
    @Published private(set) var characterDetailsError: ApiClientError?
    
    @Published private(set) var locationDetails: LocationDetailsResponseModel?
    @Published private(set) var characterDoNotHaveLocation: Bool = false
    @Published private(set) var locationDetailsError: ApiClientError?
    @Published private(set) var isDownloadingLocationDetails: Bool = false
    
    @Published private(set) var title: String = "-"
    
    @Published private(set) var characterPhoto: ImageModel?
    @Published private(set) var popularityName: String = "-"
    @Published private(set) var url: String = "-"
    @Published private(set) var created: String = "-"
    @Published private(set) var details: String = "-"

    
    var characterErrors: [ApiClientError] {
        var result = [ApiClientError]()
        if let characterDetailsError {
            result.append(characterDetailsError)
        }
        if let locationDetailsError {
            result.append(locationDetailsError)
        }
        return result
    }
    
    private var cancellables = [AnyCancellable]()
    private var locationModel: LocationDetailsModel?
    private var locationCancellables = [AnyCancellable]()
    
    
    let id: Int
    private let appRepository: AppRepository
    private let characterModel: CharacterDetailsModel
    
    
    init(
        id: Int, appRepository: AppRepository
    ) {
        self.id = id
        self.appRepository = appRepository
        characterModel = appRepository.characters.getDetails(id: id)
        
        processCharacterFromListResponse(character: characterModel.lastListResponse)
        characterModel.lastListResponsePublisher.sink { [weak self] in
            self?.processCharacterFromListResponse(character: $0)
        }.store(in: &cancellables)
        processCharacterDetailsResponse(response: characterModel.lastApiDetails)
        characterModel.lastApiDetailsPublisher.sink { [weak self] in
            self?.processCharacterDetailsResponse(response: $0)
        }.store(in: &cancellables)
    }
    
    private func processCharacterFromListResponse(character: CharacterResponseModel?) {
        self.characterFromListDetails = character
        guard let character else { return }
        if characterDetails == nil {
            title = character.name
            characterPhoto = URL(string: character.image).map { appRepository.images.getImage(url: $0) }
            popularityName = AppearanceFrequency(count: character.episode.count).popularity
            url = character.url
            created = character.created
        }
        fetchLocationIfPossible()
    }
    
    private func processCharacterDetailsResponse(response: Result<CharacterDetailsResponseModel, ApiClientError>?) {
        switch response {
        case .success(let characterDetails):
            self.characterDetails = characterDetails
            self.characterDetailsError = nil
            
            title = characterDetails.character.name
            characterPhoto = URL(string: characterDetails.character.image).map { appRepository.images.getImage(url: $0) }
            popularityName = AppearanceFrequency(count: characterDetails.character.episode.count).popularity
            url = characterDetails.character.url
            created = characterDetails.character.created
            details = characterDetails.details
        case .failure(let error):
            self.characterDetails = nil
            self.characterDetailsError = error
            title = "-"
            characterPhoto = nil
            popularityName = "-"
            url = "-"
            created = "-"
            details = "-"
            processCharacterFromListResponse(character: characterFromListDetails)
        case nil:
            self.characterDetails = nil
            self.characterDetailsError = nil
            title = "-"
            characterPhoto = nil
            popularityName = "-"
            url = "-"
            created = "-"
            details = "-"
            processCharacterFromListResponse(character: characterFromListDetails)
        }
        fetchLocationIfPossible()
    }
    
    private func fetchLocationIfPossible() {
        guard let locationUrl: String = characterDetails?.character.location.url ?? characterFromListDetails?.location.url
        else { return }
        guard let newLocationModel = appRepository.locations.getLocation(urlString: locationUrl) else {
            locationModel = nil
            for cancellable in locationCancellables {
                cancellable.cancel()
            }
            locationCancellables = []
            characterDoNotHaveLocation = true
            locationDetails = nil
            locationDetailsError = nil
            isDownloadingLocationDetails = false
            return
        }
        guard newLocationModel !== locationModel else { return }
        locationModel = newLocationModel
        characterDoNotHaveLocation = false
        for cancellable in locationCancellables {
            cancellable.cancel()
        }
        locationCancellables = []
        
        processLocationDetails(result: newLocationModel.lastApiDetails)
        newLocationModel.lastApiDetailsPublisher.sink { [weak self] result in
            self?.processLocationDetails(result: result)
        }.store(in: &locationCancellables)
        isDownloadingLocationDetails = newLocationModel.isDownloading
        newLocationModel.isDownloadingPublisher.sink { [weak self] in
            self?.isDownloadingLocationDetails = $0
        }.store(in: &locationCancellables)
        newLocationModel.downloadIfNeeded()
    }
    
    private func processLocationDetails(result: Result<LocationDetailsResponseModel, ApiClientError>?) {
        switch result {
        case .success(let locationDetails):
            self.locationDetails = locationDetails
            self.locationDetailsError = nil
        case .failure(let error):
            self.locationDetails = nil
            self.locationDetailsError = error
            showsLocationDetailsView = false
        case nil:
            self.locationDetails = nil
            self.locationDetailsError = nil
        }
    }
    
    func downloadIfNeeded() {
        characterModel.downloadIfNeeded()
        locationModel?.downloadIfNeeded()
        locationDetailsError = nil
        characterDetailsError = nil
    }
}


struct CharacterDetailView: View {
    @StateObject var viewModel: CharacterDetailViewModel
    
    
    init(id: Int, appRepository: AppRepository) {
        _viewModel = StateObject(wrappedValue: CharacterDetailViewModel(id: id, appRepository: appRepository))
    }
    
    
    
    var body: some View {
        content
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.downloadIfNeeded) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .id(viewModel.id)
    }
}

private extension CharacterDetailView {
    @ViewBuilder var content: some View {
        if let characterDetailsError = viewModel.characterDetailsError {
            FetchRetryView(
                mainMessage: "Unable to download details of character",
                underlyingError: characterDetailsError,
                onRetry: { viewModel.downloadIfNeeded() }
            )
        } else if let locationDetailsError = viewModel.locationDetailsError {
            FetchRetryView(
                mainMessage: "Unable to download current location of character",
                underlyingError: locationDetailsError,
                onRetry: { viewModel.downloadIfNeeded() }
            )
        } else if viewModel.characterDetails != nil || viewModel.characterFromListDetails != nil {
            ScrollView {
                VStack(alignment: .leading) {
                    photoSection
                    detailsSection
                    locationSection
                }
            }
        } else {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .onAppear {
                    viewModel.downloadIfNeeded()
                }
        }
    }
}

// MARK: - Section: Photo

private extension CharacterDetailView {
    var photoSection: some View {
        HStack(alignment: .center, spacing: 8) {
            CharacterPhoto(imageModel: viewModel.characterPhoto)
                .aspectRatio(1, contentMode: .fill)
                .frame(height: UIScreen.main.bounds.height / 5)
                .cornerRadius(5)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
    }
}



// MARK: - Section: About

private extension CharacterDetailView {
    var detailsSection: some View {
        VStack(alignment: .center, spacing: 8) {
           
            HStack {
                Text("Popularity level:")
                    .font(.headline)
                Text(viewModel.popularityName)
                    .font(.headline)
            }
            
            Spacer()
            
            Text("About")
                .font(.headline)
            
            if viewModel.characterDetails != nil {
                Text(viewModel.details)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .padding(.leading, 4)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .onAppear {
                        viewModel.downloadIfNeeded()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80.0)
            }
        }
        .padding()
    }
}

// MARK: - Section: Location

private extension CharacterDetailView {
    var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Location")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.showsLocationDetailsView = true
                }) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .accentColor(.orange)
                }
            }
        }
        .padding()
        .sheet(isPresented: $viewModel.showsLocationDetailsView) {
            if let locationDetail = viewModel.locationDetails {
                VStack(alignment: .leading) {
                    Text(locationDetail.name)
                        .font(.headline)
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    Text(locationDetail.created)
                        .font(.headline)
                    
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    List(locationDetail.residents, id: \.self) { resident in
                        HStack(alignment: .top) {
                            Text(resident)
                        }
                        
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .onAppear {
                        viewModel.downloadIfNeeded()
                    }
            }
        }
    }    
}
    
// MARK: - Preview
struct CharacterDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CharacterDetailView(id: 1, appRepository: AppRepository.previewInstance)
    }
}
