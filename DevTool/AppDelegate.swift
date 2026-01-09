//
//  AppDelegate.swift
//  DevTool
//
//  Created by Cardiell on 07/01/26.
//

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try ProxyInspectorManager.shared.start()
            print("Proxy Inspector started")
        } catch {
            print("Failed to start Proxy Inspector: \(error)")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        ProxyInspectorManager.shared.stop()
        print("Proxy Inspector stopped")
    }
}
