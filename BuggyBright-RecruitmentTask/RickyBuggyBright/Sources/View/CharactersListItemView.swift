//
//  CharactersListItemView.swift
//  RickyBuggyBright
//

import SwiftUI

struct CharactersListItemView: View {
    @ObservedObject private var viewModel: CharactersListItemViewModel
    
    init(viewModel: CharactersListItemViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack {
            CharacterPhoto(data: viewModel.characterImageData)
                .aspectRatio(1, contentMode: .fill)
                .frame(height: UIScreen.main.bounds.height / 5)
                .cornerRadius(5)
            
            VStack(alignment: .leading) {
                Spacer()
                
                HStack(alignment: .center) {
                    Text(viewModel.title)
                        .titleStyle()
                                                            
                    Spacer()
                }
                
                Spacer()

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        // FIXME: 6 - Make URL tappable
                        Text(viewModel.url)

                        Text(viewModel.created)
                            .contentsStyle()
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Preview

struct characterListCell_Previews: PreviewProvider {
    static var previews: some View {
        CharactersListItemView(viewModel: CharactersListItemViewModel(character: .dummy))
            .frame(maxHeight: UIScreen.main.bounds.height / 5)
    }
}
