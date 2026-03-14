//
//  CharactersListView.swift
//  RickyBuggyBright
//

import SwiftUI

struct CharactersListView: View {
    @Binding private var characters: [CharacterResponseModel]
    @Binding private var sortMethod: SortMethod
    
    init(characters: Binding<[CharacterResponseModel]>, sortMethod: Binding<SortMethod>) {
        _characters = characters
        _sortMethod = sortMethod
    }
    
    var body: some View {
        List(characters) { character in
            let destinationViewModel = CharacterDetailViewModel(characterId: character.id, name: character.name)
            let destination = CharacterDetailView(viewModel: destinationViewModel)

            NavigationLink(destination: destination) {
                let viewModel = CharactersListItemViewModel(character: character)

                CharactersListItemView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Preview

struct CharactersListView_Previews: PreviewProvider {
    static var previews: some View {
        CharactersListView(characters: .constant([.dummy]), sortMethod: .constant(.name))
    }
}
