//
//  RickyBuggyBrightApp.swift
//  RickyBuggyBright
//

import SwiftUI


@MainActor
private let appRepository = AppRepository()

@main
struct RickyBuggyBrightApp: App {
    
    @State var isListHidden = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                VStack {
                    Button("Hide Content") {
                        isListHidden = true
                    }
                    AppMainView(appRespository: appRepository)
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
