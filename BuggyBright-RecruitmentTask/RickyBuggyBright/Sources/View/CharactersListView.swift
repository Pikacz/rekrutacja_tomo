//
//  CharactersListView.swift
//  RickyBuggyBright
//

import SwiftUI

struct CharactersListView: View {
    @Binding private var characters: [CharacterResponseModel]
    @Binding private var charactersSortedIndicies: [Int]
    
    init(characters: Binding<[CharacterResponseModel]>, charactersSortedIndicies: Binding<[Int]>) {
        _characters = characters
        _charactersSortedIndicies = charactersSortedIndicies
    }
    
    var body: some View {
        List(charactersSortedIndicies, id: \.self) { characterIdx in
            let character = characters[characterIdx]
            let destinationViewModel = CharacterDetailViewModel(characterId: character.id, name: character.name)
            let destination = CharacterDetailView(viewModel: destinationViewModel)

            NavigationLink(destination: destination) {
                
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
        CharactersListView(characters: .constant([.dummy]), charactersSortedIndicies: .constant([0]))
    }
}
