//
//  CharacterPhoto.swift
//  RickyBuggyBright
//

import UIKit
import SwiftUI

struct CharacterPhoto: View {
    private let data: Data?
    
    init(data: Data?) {
        self.data = data
    }
    
    var body: some View {
        if let data = data, let posterUIImage = UIImage(data: data) {
            return AnyView(
                Image(uiImage: posterUIImage)
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
        CharacterPhoto(data: nil)
    }
}
