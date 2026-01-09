//
//  CertificateInstaller.swift
//  DevTool
//
//  Created by OpenAI on 2025-01-07.
//

import Foundation

enum CertificateInstallerError: LocalizedError {
    case invalidURL
    case invalidResponse
    case downloadFailed(status: Int)
    case commandFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "No se pudo construir la URL del certificado."
        case .invalidResponse:
            return "La respuesta del servidor no es válida."
        case .downloadFailed(let status):
            return "Falló la descarga del certificado (HTTP \(status))."
        case .commandFailed(let message):
            return "No se pudo instalar el certificado: \(message)"
        }
    }
}

struct CertificateInstaller {
    static func installCertificate(host: String, port: Int) async throws {
        guard let url = URL(string: "http://\(host):\(port)/proxy/cert") else {
            throw CertificateInstallerError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CertificateInstallerError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw CertificateInstallerError.downloadFailed(status: httpResponse.statusCode)
        }

        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("devtool-cert", isDirectory: true)
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let certURL = tempDirectory.appendingPathComponent("DevTool-Proxy-Cert.cer")
        try data.write(to: certURL, options: .atomic)

        let loginKeychain = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Keychains/login.keychain-db")
            .path

        try runProcess(
            "/usr/bin/security",
            arguments: [
                "add-trusted-cert",
                "-d",
                "-r",
                "trustRoot",
                "-k",
                loginKeychain,
                certURL.path
            ]
        )
    }

    private static func runProcess(_ launchPath: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? "Error desconocido."
            throw CertificateInstallerError.commandFailed(message: output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
