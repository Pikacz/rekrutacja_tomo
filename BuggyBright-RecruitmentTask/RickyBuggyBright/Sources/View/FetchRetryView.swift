//
//  FetchRetryView.swift
//  RickyBuggyBright
//

import SwiftUI

struct FetchRetryView: View {
    private let errors: [ApiClientError]
    private let onRetry: () -> Void
    
    init(errors: [ApiClientError], onRetry: @escaping () -> Void) {
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
                    ForEach(errors.indices, id: \.self) { errorIndex in
                        // FIXME: Error screen!
                        Text("\(errors[errorIndex])")
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
        FetchRetryView(errors: [.unexpectedError], onRetry: {})
    }
}
