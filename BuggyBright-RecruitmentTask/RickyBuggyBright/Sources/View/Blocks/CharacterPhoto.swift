//
//  CharacterPhoto.swift
//  RickyBuggyBright
//

import UIKit
import SwiftUI

struct CharacterPhoto: View {
    private let image: UIImage?
    
    init(image: UIImage?) {
        self.image = image
    }
    
    var body: some View {
        if let image {
            return AnyView(
                Image(uiImage: image)
                    .resizable()
            )
        } else {
            return AnyView(placeholder)
        }
    }
}

// MARK: - View

private extension CharacterPhoto {
    var placeholder: some View {
        Image(systemName: "photo")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - Preview

struct CharacterPhoto_Previews: PreviewProvider {
    static var previews: some View {
        CharacterPhoto(image: nil)
    }
}
