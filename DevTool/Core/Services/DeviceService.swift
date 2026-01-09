//
//  SimctlService.swift
//  DevTool
//
//  Created by Cardiell on 06/01/26.
//

import Foundation

class DeviceService {
    /// Obtiene todos los dispositivos (simuladores + físicos) y sus datos reales
    static func fetchDevices() async throws -> [DeviceInfo] {
        let simulators = try await fetchSimulators()
        let physicals = fetchPhysicalDevices(excluding: simulators.map { $0.udid })
        return simulators + physicals
    }
    
    /// Obtiene simuladores y sus datos reales
    private static func fetchSimulators() async throws -> [DeviceInfo] {
        var devices: [DeviceInfo] = []
        // 1. Dispositivos
        let simctlTask = Process()
        simctlTask.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        simctlTask.arguments = ["simctl", "list", "devices", "--json"]
        let outputPipe = Pipe()
        simctlTask.standardOutput = outputPipe
        try simctlTask.run()
        simctlTask.waitUntilExit()
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devicesDict = json["devices"] as? [String: [[String: Any]]] else {
            return []
        }
        // 2. Modelos por devicetype
        let typeTask = Process()
        typeTask.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        typeTask.arguments = ["simctl", "list", "devicetypes", "--json"]
        let typePipe = Pipe()
        typeTask.standardOutput = typePipe
        try typeTask.run()
        typeTask.waitUntilExit()
        let typeData = typePipe.fileHandleForReading.readDataToEndOfFile()
        var devTypeDict: [String: String] = [:]
        if let typesJSON = try? JSONSerialization.jsonObject(with: typeData) as? [String: Any],
           let types = typesJSON["devicetypes"] as? [[String: Any]] {
            for type in types {
                if let name = type["name"] as? String, let identifier = type["identifier"] as? String {
                    devTypeDict[name] = identifier
                }
            }
        }
        // 3. Recopila info por simulador
        for (runtime, deviceList) in devicesDict {
            for device in deviceList {
                guard let name = device["name"] as? String,
                      let udid = device["udid"] as? String,
                      let state = device["state"] as? String else { continue }
                // Modelo (solo nombre, el identificador de devicetypes, si aplica)
                let model: String? = devTypeDict.keys.first(where: { name.contains($0) }) ?? nil
                // App activa (simctl get_app_container solo disponible si booted y tienes bundle id, aquí lo dejamos nil por default)
                devices.append(
                    DeviceInfo(
                        name: name,
                        udid: udid,
                        state: state,
                        runtime: runtime,
                        type: .simulator,
                        model: model,
                        freeSpace: nil,   // puedes obtenerlo montando la sandbox y revisando el espacio con FileManager
                        batteryLevel: nil, // simulador no tiene batería real
                        ipAddress: "127.0.0.1", // siempre localhost para simulador
                        runningApp: nil   // Si sabes bundle id, puedes usar simctl launch y trackear
                    )
                )
            }
        }
        return devices
    }
    
    /// Obtiene físicos conectados y sus datos reales
    static func fetchPhysicalDevices(excluding knownSimulators: [String]) -> [DeviceInfo] {
        var devices: [DeviceInfo] = []
        let xctrace = Process()
        xctrace.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        xctrace.arguments = ["xctrace", "list", "devices"]
        let pipe = Pipe()
        xctrace.standardOutput = pipe
        try? xctrace.run()
        xctrace.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        let lines = output.components(separatedBy: .newlines)
        let regex = try! NSRegularExpression(pattern: #"^(.+?) \(([\d\.]+)\) \(([0-9A-F\-]+)\)$"#)
        for line in lines {
            let nsline = line as NSString
            if let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsline.length)) {
                let name = nsline.substring(with: match.range(at: 1))
                let runtime = nsline.substring(with: match.range(at: 2))
                let udid = nsline.substring(with: match.range(at: 3))
                // Evita duplicados
                if knownSimulators.contains(udid) || name.contains("Simulator") { continue }
                // Modelo, espacio, batería, IP, running app: usa libimobiledevice
                let model = execRead("ideviceinfo", ["-u", udid, "-k", "ProductType"])
                let freeSpace = execRead("ideviceinfo", ["-u", udid, "-k", "TotalDataAvailable"])
                let batteryLevel = execRead("ideviceinfo", ["-u", udid, "-k", "BatteryCurrentCapacity"])
                let ipAddress = execRead("ideviceinfo", ["-u", udid, "-k", "WiFiAddress"])
                // Nota: Para app corriendo usa otros métodos (sólo si hay proceso visible/debug, puede ser nil normalmente)
                devices.append(
                    DeviceInfo(
                        name: name,
                        udid: udid,
                        state: "connected",
                        runtime: runtime,
                        type: .physical,
                        model: model,
                        freeSpace: freeSpace,
                        batteryLevel: batteryLevel.map { "\($0)%" },
                        ipAddress: ipAddress,
                        runningApp: nil // Requiere integración avanzada (solo posible en modo debug/inspector)
                    )
                )
            }
        }
        return devices
    }

    /// Ejecuta y devuelve el primer resultado sin salto de línea
    private static func execRead(_ tool: String, _ arguments: [String]) -> String? {
        let task = Process()
        task.launchPath = "/usr/local/bin/\(tool)" // Así queda tras instalar con Homebrew
        task.arguments = arguments
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let out = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines), !out.isEmpty else { return nil }
            return out
        } catch {
            return nil
        }
    }
}
