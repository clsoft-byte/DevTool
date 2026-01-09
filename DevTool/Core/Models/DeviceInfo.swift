//
//  DeviceInfo.swift
//  DevTool
//
//  Created by Cardiell on 07/01/26.
//

import Foundation

struct DeviceInfo: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let udid: String
    let state: String
    let runtime: String
    let type: DeviceType
    let model: String?          // e.g. "iPhone14,2"
    let freeSpace: String?      // e.g. "15.2 GB"
    let batteryLevel: String?   // e.g. "85%"
    let ipAddress: String?      // e.g. "192.168.0.5"
    let runningApp: String?     // e.g. "com.mycompany.myapp"
}

enum DeviceType: String {
    case simulator = "Simulador"
    case physical = "Físico"
}
