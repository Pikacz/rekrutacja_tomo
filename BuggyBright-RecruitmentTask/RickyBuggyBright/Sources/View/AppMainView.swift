//
//  AppMainView.swift
//  RickyBuggyBright
//

import Combine
import SwiftUI


@MainActor
final class AppMainViewModel: ObservableObject {
    @Published private(set) var sortingMethod: SortMethod? = nil
    @Published private(set) var downloadedCharacters: [CharacterResponseModel] = []
    @Published var sortedCharactersIndicies: [IndexWithId] = []
    @Published private(set) var downloadError: ApiClientError? = nil
    @Published var showsSortActionSheet: Bool = false
    
    
    private var cancellables = [AnyCancellable]()
    
    let appRespository: AppRepository
    
    var id: ObjectIdentifier { return ObjectIdentifier(appRespository) }
    
    init(appRespository: AppRepository) {
        self.appRespository = appRespository
        processCharactersResponse(
            result: appRespository.characters.lastAllCharacters
        )
        appRespository.characters.lastAllCharactersPublisher.sink { [weak self] result in
            DispatchQueue.main.async {
                self?.processCharactersResponse(result: result)
            }
        }.store(in: &cancellables)
    }
    
    private func processCharactersResponse(result: Result<[CharacterResponseModel], ApiClientError>?) {
        switch result {
        case .success(let characters):
            downloadedCharacters = characters
            sortedCharactersIndicies = characters.indices.map {
                IndexWithId(index: $0, id: characters[$0].id)
            }
            if let sortingMethod {
                sortCharacters(sortingMethod)
            }
            
        case .failure(let error):
            downloadedCharacters = []
            sortedCharactersIndicies = []
            downloadError = error
        case nil:
            downloadedCharacters = []
            sortedCharactersIndicies = []
            downloadError = nil
        }
    }
    
    
    private func sortCharacters(_ method: SortMethod?) {
        switch method {
        case .name:
            sortedCharactersIndicies.sort { lhs, rhs in
                downloadedCharacters[lhs.index].name < downloadedCharacters[rhs.index].name
            }
        case .episodesCount:
            sortedCharactersIndicies.sort { lhs, rhs in
                downloadedCharacters[lhs.index].episode.count > downloadedCharacters[rhs.index].episode.count
            }
        case nil:
            sortedCharactersIndicies.sort {
                $0.index < $1.index
            }
        }
    }
    
    func setSorting(_ method: SortMethod?) {
        self.sortingMethod = method
        sortCharacters(sortingMethod)
    }
    
    func downloadIfNeeded() {
        appRespository.characters.downloadAllCharactersIfNeeded()
    }
}


struct AppMainView: View {
    @StateObject var viewModel: AppMainViewModel
    private let appRespository: AppRepository
    
    

    
    init(
        appRespository: AppRepository
    ) {
        self._viewModel = StateObject(wrappedValue: AppMainViewModel(appRespository: appRespository))
        self.appRespository = appRespository
    }
        
    var body: some View {
        NavigationView {
            
            characterListView
                .navigationTitle(Text("Characters"))
                .navigationBarTitleDisplayMode(.automatic)
                .addNonGlitchyBottomToolbar { sortButton }
        }
        .id(viewModel.id)
        .onAppear {
            viewModel.downloadIfNeeded()
        }
        
    }
    
    private func setSortingAnimated(_ method: SortMethod?) {
        guard viewModel.sortingMethod != method else { return }
        withAnimation {
            viewModel.setSorting(method)
        }
    }
    
    @ViewBuilder private var characterListView: some View {
        if viewModel.downloadedCharacters.isEmpty == false {
            CharactersListView(
                characters: viewModel.downloadedCharacters,
                charactersSortedIndicies: viewModel.sortedCharactersIndicies,
                appRepository: appRespository
            )
        } else if let downloadError = viewModel.downloadError {
            FetchRetryView(
                mainMessage: "Unable to download list of characters",
                underlyingError: downloadError,
                onRetry: {
                    viewModel.downloadIfNeeded()
                }
            )
        } else {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
    }

    var sortButton: some View {
        Button(action: { viewModel.showsSortActionSheet = true }) {
            Text("Choose Sorting")
        }
        .addSortActionSheet(
            isPresented: $viewModel.showsSortActionSheet,
            onSelect: {
                self.setSortingAnimated($0)
            }
        )
    }
}

private extension View {
    @ViewBuilder
    func addSortActionSheet(
        isPresented: Binding<Bool>,
        onSelect: @escaping @MainActor (SortMethod?) -> Void
    ) -> some View {
        if #available(iOS 26.0, *) {
            self
                .confirmationDialog(
                    "Choose sorting method",
                    isPresented: isPresented,
                    titleVisibility: .visible
                ) {
                    Button("Episodes Count") {
                        onSelect(.episodesCount)
                    }
                    Button("Name") {
                        onSelect(.name)
                    }
                    Button("Default") {
                        onSelect(nil)
                    }
                    
                }
        } else {
            self.actionSheet(isPresented: isPresented) {
                ActionSheet(
                    title: Text("Sort method"),
                    message: Text("Choose sorting method"),
                    buttons: [
                        .default(Text("Episodes Count")) {
                            onSelect(.episodesCount)
                        },
                        .default(Text("Name")) {
                            onSelect(.name)
                            
                        },
                        .default(Text("Default")) {
                            onSelect(nil)
                        },
                        
                        .cancel(Text("Cancel")),
                    ]
                )
            }
        }
    }
}


// MARK: - Preview

struct AppMainView_Previews: PreviewProvider {
    static var previews: some View {
        AppMainView(appRespository: AppRepository.previewInstance)
    }
}
