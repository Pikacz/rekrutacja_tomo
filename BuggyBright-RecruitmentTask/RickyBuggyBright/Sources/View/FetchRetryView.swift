//
//  FetchRetryView.swift
//  RickyBuggyBright
//

import SwiftUI

struct FetchRetryView: View {
    private let mainMessage: String
    private let underlyingError: ApiClientError
    private let onRetry: () -> Void
    
    @State var canShowDebug = false
    
    init(
        mainMessage: String,
        underlyingError: ApiClientError,
        onRetry: @escaping () -> Void
    ) {
        self.mainMessage = mainMessage
        self.underlyingError = underlyingError
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text(mainMessage)
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                Text(underlyingError.userMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if canShowDebug {
                    Text(underlyingError.debuggingInformation)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            if canShowDebug {
                Button(action: {
                    UIPasteboard.general.string = underlyingError.debuggingInformation
                }) {
                    Text("Copy debugging infromation")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .padding()
            }
            
            Button(action: onRetry) {
                Text("Retry")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding()
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture(count: 5) {
            canShowDebug = true
        }
    }
}

extension ApiClientError {
    var userMessage: String {
        switch self {
        case .networkError(let error):
            switch error {
            case .internetDisabled:
                return "It seems that you disabled internet access. It's required in order to use the application."
            case .noNetworkAccess:
                return "Unable to connect with the server. Check your internet connection and try again later."
            case .otherNetworkingError:
                return "Unable to connect with the server. Please try again later."
            }
        case .unexpectedError:
            return "Unexpected error happened. Check if your application is updated and try again later."
        }
    }
    
    var debuggingInformation: String {
        return "\(self)"
    }
}

// MARK: - Preview

struct FetchRetryView_Previews: PreviewProvider {
    static var previews: some View {
        FetchRetryView(
            mainMessage: "An error occured!",
            underlyingError: .networkError(error: .internetDisabled(genericError: nil)),
            onRetry: {}
        )
    }
}
