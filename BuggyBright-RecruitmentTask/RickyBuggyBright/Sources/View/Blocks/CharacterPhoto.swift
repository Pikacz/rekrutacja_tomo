//
//  CharacterPhoto.swift
//  RickyBuggyBright
//

import Combine
import UIKit
import SwiftUI

struct CharacterPhoto: View {
    private let imageModel: ImageModel?
    
    private let imagePublisher: AnyPublisher<UIImage?, Never>
    
    @State private var image: UIImage?
    
    init(imageModel: ImageModel?) {
        self.imageModel = imageModel
        self.imagePublisher = imageModel?.lastApiDetailsPublisher.map { apiResult in
            switch apiResult {
            case .success(let image):
                return image
            case .failure, nil:
                return nil
            }
        }.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
        switch imageModel?.lastApiDetails {
        case .success(let image):
            self.image = image
        case .failure, nil:
            self.image = nil
        }
    }
    
    var body: some View {
        AnyView(content)
            .onReceive(imagePublisher) { image in
                self.image = image
            }
            .onAppear {
                self.imageModel?.downloadIfNeeded()
            }
            .id(ObjectIdentifier(imageModel))
    }
}

// MARK: - View

private extension CharacterPhoto {
    var content: some View {
        if let image {
            return AnyView(
                Image(uiImage: image)
                    .resizable()
            )
        } else {
            return AnyView(placeholder)
        }
    }
    
    var placeholder: some View {
        Image(systemName: "photo")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - Preview

struct CharacterPhoto_Previews: PreviewProvider {
    static var previews: some View {
        CharacterPhoto(imageModel: nil)
    }
}
