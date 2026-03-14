//
//  RickyBuggyBrightApp.swift
//  RickyBuggyBright
//

import SwiftUI

@main
struct RickyBuggyBrightApp: App {
    
    @State var isListHidden = true
    
    init() {
        DIContainer.shared.register(NetworkManager())
        DIContainer.shared.register(APIClient())
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                Button(isListHidden ? "Hide Content" : "Show Content") {
                    isListHidden = !isListHidden
                }
                
                if(isListHidden) {
                    AppMainView()
                }
            }
        }
    }
}
