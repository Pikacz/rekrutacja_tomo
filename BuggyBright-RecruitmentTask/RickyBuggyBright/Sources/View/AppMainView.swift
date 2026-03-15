//
//  AppMainView.swift
//  RickyBuggyBright
//

import Combine
import SwiftUI

struct AppMainView: View {
    private let appRespository: AppRepository
    
    @State var sortingMethod: SortMethod? = nil
    @State var downloadedCharacters: [CharacterResponseModel] = []
    @State var sortedCharactersIndicies: [Int] = []
    @State var downloadError: ApiClientError? = nil
    @State var showsSortActionSheet: Bool = false
    
    
    init(
        appRespository: AppRepository
    ) {
        self.appRespository = appRespository
        processCharactersResponse(
            result: appRespository.characters.lastAllCharacters
        )
    }
    
    // FIXME: 13 - fix issue with re-invoking processing on tapping show list/hide list
    private func processCharactersResponse(result: Result<[CharacterResponseModel], ApiClientError>?) {
        print("🦖🦕 processing response - make sure that this is not called to often!")
        switch result {
        case .success(let characters):
            downloadedCharacters = characters
            sortedCharactersIndicies = [Int](characters.indices)
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
                downloadedCharacters[lhs].name < downloadedCharacters[rhs].name
            }
        case .episodesCount:
            sortedCharactersIndicies.sort { lhs, rhs in
                downloadedCharacters[lhs].episode.count > downloadedCharacters[rhs].episode.count
            }
        case nil:
            sortedCharactersIndicies.sort()
        }
    }
    
    private func setSorting(_ method: SortMethod?) {
        self.sortingMethod = method
        sortCharacters(sortingMethod)
    }
    
    var body: some View {
        NavigationView {
            characterListView
                .navigationTitle(Text("Characters"))
                .navigationBarTitleDisplayMode(.automatic)
                // FIXME: 7 - Fix issue with glitching toolbar on entering details view
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        sortButton
                    }
                }
        }
        .onAppear {
            appRespository.characters.downloadAllCharactersIfNeeded()
        }
        .onReceive(appRespository.characters.lastAllCharactersPublisher) {
            self.processCharactersResponse(result: $0)
        }
        .actionSheet(isPresented: $showsSortActionSheet) {
            sortActionSheet
        }
    }
}

// MARK: - View

private extension AppMainView {
    @ViewBuilder var characterListView: some View {
        if downloadedCharacters.isEmpty == false {
            CharactersListView(characters: $downloadedCharacters, charactersSortedIndicies: $sortedCharactersIndicies)
        } else if let downloadError {
            // FIXME: Error messages
            FetchRetryView(errors: [downloadError], onRetry: {
                appRespository.characters.downloadAllCharactersIfNeeded()
            })
        } else {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
    }

    var sortButton: some View {
        Button(action: { showsSortActionSheet = true }) {
            Text("Choose Sorting")
        }
    }
    
    // FIXME: 8 - Fix action sheet only appearing once, in other words - after it gets opened and closed, it cannot be opened again
    var sortActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Sort method"),
            message: Text("Choose sorting method"),
            buttons: [
                .default(Text("Episodes Count")) {
                    setSorting(.episodesCount)
                },
                .default(Text("Name")) {
                    setSorting(.name)
                    
                },
                .default(Text("Default")) {
                    setSorting(nil)
                },
                
                .cancel(Text("Cancel")),
            ]
        )
    }
}

// MARK: - Preview

struct AppMainView_Previews: PreviewProvider {
    static var previews: some View {
        AppMainView(appRespository: AppRepository.shared)
    }
}
