//
//  CharactersListItemView.swift
//  RickyBuggyBright
//

import SwiftUI

struct CharactersListItemView: View {
    private let title: String
    private let created: String
    private let url: String
    private let image: ImageModel?
    
    init(title: String, created: String, url: String, image: ImageModel?) {
        self.title = title
        self.created = created
        self.url = url
        self.image = image
    }
    
    var body: some View {
        HStack {
            CharacterPhoto(imageModel: image)
                .aspectRatio(1, contentMode: .fill)
                .frame(height: UIScreen.main.bounds.height / 5)
                .cornerRadius(5)
            
            VStack(alignment: .leading) {
                Spacer()
                
                HStack(alignment: .center) {
                    Text(title)
                        .titleStyle()
                                                            
                    Spacer()
                }
                
                Spacer()

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let parsedUrl = URL(string: url) {
                            Text(url)
                                .underline()
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    UIApplication.shared.open(parsedUrl)
                                }
                        } else {
                            Text(url)
                        }
                        Text(created)
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
        CharactersListItemView(
            title: CharacterResponseModel.dummy.name,
            created: CharacterResponseModel.dummy.created,
            url: CharacterResponseModel.dummy.url,
            image: AppRepository.previewInstance.images.getOptionalImage(
                url: URL(string: CharacterResponseModel.dummy.image)
            )
        )
    }
}
