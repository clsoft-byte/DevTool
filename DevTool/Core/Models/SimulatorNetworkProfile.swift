//
//  SimulatorNetworkProfile.swift
//  DevTool
//
//  Created by Cardiell on 07/01/26.
//

enum SimulatorNetworkProfile: String, CaseIterable, Identifiable {
    case wifi
    case lte
    case threeG
    case edge
    case offline

    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .wifi: return "WiFi (Buena)"
        case .lte: return "LTE"
        case .threeG: return "3G"
        case .edge: return "EDGE (lenta)"
        case .offline: return "Sin red"
        }
    }
    var simctlProfileName: String {
        switch self {
        case .wifi: return "WiFi"
        case .lte: return "LTE"
        case .threeG: return "3G"
        case .edge: return "Edge"
        case .offline: return "100% Loss"
        }
    }
}
