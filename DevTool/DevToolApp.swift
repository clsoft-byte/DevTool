//
//  DevToolApp.swift
//  DevTool
//
//  Created by Cardiell on 06/01/26.
//

import SwiftUI
import SwiftData

@main
struct DevToolApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
