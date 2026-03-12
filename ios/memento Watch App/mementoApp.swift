//
//  memento_watchosApp.swift
//  memento_watchos Watch App
//
//  Created by liao on 2026/3/9.
//

import SwiftUI

@main
struct memento_watchos_Watch_AppApp: App {
    init() {
        // 初始化 WCSessionManager
        _ = WCSessionManager.shared
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
