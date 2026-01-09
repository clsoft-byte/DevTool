//
//  SimulatorNetworkService.swift
//  DevTool
//
//  Created by Cardiell on 07/01/26.
//

import Foundation

struct SimulatorNetworkService {
    static func applyNetworkProfile(simulatorUDID: String, profile: SimulatorNetworkProfile) throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        task.arguments = [
            "simctl", "spawn", simulatorUDID,
            "defaults", "write", "/Library/Preferences/com.apple.networkLinkConditioner.plist",
            "ActiveProfile", "-string", profile.simctlProfileName
        ]
        try task.run()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else {
            throw NSError(domain: "SimulatorNetwork", code: Int(task.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: "No se pudo aplicar el perfil de red"
            ])
        }
    }

    static func disableConditioner(simulatorUDID: String) throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        task.arguments = [
            "simctl", "spawn", simulatorUDID,
            "defaults", "delete", "/Library/Preferences/com.apple.networkLinkConditioner.plist",
            "ActiveProfile"
        ]
        try task.run()
        task.waitUntilExit()
    }

    static func getActiveNetworkProfile(simulatorUDID: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        task.arguments = [
            "simctl", "spawn", simulatorUDID,
            "defaults", "read", "/Library/Preferences/com.apple.networkLinkConditioner.plist",
            "ActiveProfile"
        ]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }
}
