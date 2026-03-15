//
//  CharactersListView.swift
//  RickyBuggyBright
//

import SwiftUI

struct CharactersListView: View {
    let characters: [CharacterResponseModel]
    let charactersSortedIndicies: [IndexWithId]
    
    init(characters: [CharacterResponseModel], charactersSortedIndicies: [IndexWithId]) {
        self.characters = characters
        self.charactersSortedIndicies = charactersSortedIndicies
    }
    
    var body: some View {
        List(charactersSortedIndicies, id: \.id) { characterIdx in
            let character = characters[characterIdx.index]
            
            
            NavigationLink {
                CharacterDetailView(
                    viewModel: CharacterDetailViewModel(
                        characterId: character.id,
                        name: character.name
                    )
                )
            } label: {
                CharactersListItemView(
                    title: character.name,
                    created: character.created,
                    url: character.url,
                    image: AppRepository.shared.images.getOptionalImage(url: URL(string: character.image))
                )
            }
        }
    }
}

// MARK: - Preview

struct CharactersListView_Previews: PreviewProvider {
    static var previews: some View {
        CharactersListView(characters: [.dummy], charactersSortedIndicies: [IndexWithId(index: 0, id: CharacterResponseModel.dummy.id)])
    }
}
