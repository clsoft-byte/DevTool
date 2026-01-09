//
//  DevicesView.swift
//  DevTool
//
//  Created by Cardiell on 06/01/26.
//

import SwiftUI

import SwiftUI

struct DevicesView: View {
    @State private var devices: [DeviceInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Dispositivos").font(.title2).bold()
                Spacer()
                Button("Recargar") { loadDevices() }
                    .disabled(isLoading)
            }
            .padding(.horizontal)

            if isLoading {
                ProgressView("Cargando dispositivos…")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            } else if devices.isEmpty {
                Text("No hay dispositivos detectados.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(devices) { device in
                            DeviceCard(device: device)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding(.top)
        .onAppear(perform: loadDevices)
    }

    func loadDevices() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let all = try await DeviceService.fetchDevices()
                await MainActor.run {
                    self.devices = all
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct DeviceCard: View {
    let device: DeviceInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Nombre y estado
            HStack(alignment: .center, spacing: 10) {
                Text(device.name)
                    .font(.system(size: 16, weight: .bold))
                Text(device.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(device.type == .simulator ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .foregroundColor(device.type == .simulator ? .blue : .green)
                    .cornerRadius(6)
                Spacer()
                Text(device.state)
                    .font(.caption)
                    .foregroundColor(device.state == "Booted" || device.state == "connected" ? .green : .orange)
            }

            // UDID, Modelo, Versión, IP, etc.
            WrapHStack {
                Text("UDID: \(device.udid)")
                if let model = device.model { Text("Modelo: \(model)") }
                Text("Versión: \(device.runtime)")
                if let ip = device.ipAddress { Text("IP: \(ip)") }
                if let freeSpace = device.freeSpace { Text("Espacio: \(freeSpace)") }
                if let battery = device.batteryLevel { Text("Batería: \(battery)") }
                if let app = device.runningApp { Text("App: \(app)") }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // Acciones solo para simuladores
            if device.type == .simulator {
                HStack(spacing: 12) {
                    DeviceActionButton(label: "Bootear", action: { bootSimulator(device.udid) })
                    DeviceActionButton(label: "Apagar", action: { shutdownSimulator(device.udid) })
                    DeviceActionButton(label: "Abrir", action: { openSimulator(device.udid) })
                    DeviceActionButton(label: "Limpiar datos", action: { eraseSimulator(device.udid) })
                    DeviceActionButton(label: "Screenshot", action: { screenshotSimulator(device.udid) })
                }
                .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1.5)
    }

    // ---- Acciones ----
    private func bootSimulator(_ udid: String) {
        runSimctl(["boot", udid])
    }
    private func shutdownSimulator(_ udid: String) {
        runSimctl(["shutdown", udid])
    }
    private func openSimulator(_ udid: String) {
        // Abre el simulador específico en la app de Simulator
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", "Simulator", "--args", "-CurrentDeviceUDID", udid]
        try? task.run()
    }
    private func eraseSimulator(_ udid: String) {
        runSimctl(["erase", udid])
    }
    private func screenshotSimulator(_ udid: String) {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let filename = desktop.appendingPathComponent("screenshot-\(udid.prefix(6)).png")
        runSimctl(["io", udid, "screenshot", filename.path])
    }
    private func runSimctl(_ arguments: [String]) {
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["simctl"] + arguments
        try? task.run()
    }
}

// Helper: Ajusta el stack para que no se salga a la derecha si hay muchos campos
struct WrapHStack<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        HStack {
            content
            Spacer()
        }
    }
}

struct DeviceActionButton: View {
    let label: String
    let action: () -> Void
    var body: some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .font(.caption)
    }
}
