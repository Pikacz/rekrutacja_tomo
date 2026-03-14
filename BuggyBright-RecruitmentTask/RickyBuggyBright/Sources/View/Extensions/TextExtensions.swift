//
//  TextExtensions.swift
//  RickyBuggyBright
//

import SwiftUI

extension Text {
    func titleStyle() -> some View {
        return self
            .font(.title3)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    func contentsStyle() -> some View {
        return self
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
