//
//  RickyBuggyBrightApp.swift
//  RickyBuggyBright
//

import SwiftUI

@main
struct RickyBuggyBrightApp: App {
    
    @State var isListHidden = false
    
    init() {
        DIContainer.shared.register(NetworkManager())
        DIContainer.shared.register(APIClient())
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                VStack {
                    Button("Hide Content") {
                        isListHidden = true
                    }
                    
                    AppMainView(appRespository: AppRepository.shared)
                }
                .opacity(isListHidden ? 0 : 1)
                .disabled(isListHidden)
                
                if isListHidden {
                    VStack {
                        Button("Show Content") {
                            isListHidden = false
                        }
                    }
                }
            }
        }
    }
}
