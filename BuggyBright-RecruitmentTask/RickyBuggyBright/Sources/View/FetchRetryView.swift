//
//  FetchRetryView.swift
//  RickyBuggyBright
//

import SwiftUI

struct FetchRetryView: View {
    private let errors: [String]
    private let onRetry: () -> Void
    
    init(errors: [String], onRetry: @escaping () -> Void) {
        self.errors = errors
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Request Error")
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                VStack {
                    ForEach(errors, id: \.self) { error in
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button(action: onRetry) {
                Text("Retry")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding()
        }
        .padding()
    }
}

// MARK: - Preview

struct FetchRetryView_Previews: PreviewProvider {
    static var previews: some View {
        FetchRetryView(errors: ["Could not get details of location"], onRetry: {})
    }
}
