//
//  ProxyInspectorManager.swift
//  DevTool
//
//  Created by Cardiell on 07/01/26.
//

import Foundation

import Foundation

enum ProxyInspectorError: Error {
    case alreadyRunning
    case binaryNotFound
}

final class ProxyInspectorManager {

    static let shared = ProxyInspectorManager()

    private var process: Process?

    private init() {}

    // MARK: - Public API

    func start(proxyPort: Int = 8888, apiPort: Int = 9999) throws {
        guard process == nil else {
            throw ProxyInspectorError.alreadyRunning
        }

        guard let resourcePath = Bundle.main.resourcePath else {
            throw ProxyInspectorError.binaryNotFound
        }

        let binaryPath = resourcePath + "/proxy-inspector"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = [
            "-proxy", "0.0.0.0:\(proxyPort)",
            "-api", "0.0.0.0:\(apiPort)"
        ]

        process.standardOutput = Pipe()
        process.standardError = Pipe()

        process.terminationHandler = { proc in
            print("Proxy Inspector terminated with code \(proc.terminationStatus)")
        }

        try process.run()
        self.process = process
    }

    func stop() {
        guard let process else { return }

        if process.isRunning {
            process.terminate()       // SIGTERM (correcto)
            process.waitUntilExit()
        }

        self.process = nil
    }

    func isRunning() -> Bool {
        process?.isRunning == true
    }
}
