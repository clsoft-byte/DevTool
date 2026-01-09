//
//  NetworkView.swift
//  DevTool
//
//  Created by Cardiell on 07/01/26.
//

import SwiftUI
import Combine
struct NetworkView: View {

    @StateObject private var viewModel = NetworkViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Tráfico de Red (Live)")
                .font(.title2)
                .bold()

            List(viewModel.events) { event in
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.type.capitalized)
                        .font(.headline)
                        .foregroundColor(event.type == "request" ? .blue : .green)

                    if let req = event.request {
                        Text("\(req.method) \(req.url)")
                            .font(.subheadline)
                    }

                    if let resp = event.response {
                        Text("\(resp.status) [\(resp.statusCode)]")
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}



//struct NetworkView: View {
//    @State private var selectedSimulator: DeviceInfo? = nil
//    @State private var selectedProfile: SimulatorNetworkProfile = .wifi
//    @State private var error: String?
//    @State private var simulators: [DeviceInfo] = []
//    @State private var isLoading = false
//    @State private var activeProfile: String? = nil
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            HStack {
//                Text("Simulación de red").font(.title2).bold()
//                Spacer()
//                Button("Recargar simuladores") { loadSimulators() }
//                    .disabled(isLoading)
//            }
//            .padding(.horizontal)
//
//            if isLoading {
//                ProgressView("Cargando simuladores…").padding()
//            } else if simulators.isEmpty {
//                Text("No hay simuladores arrancados.").foregroundColor(.secondary)
//            } else {
//                Picker("Simulador", selection: $selectedSimulator) {
//                    ForEach(simulators) { sim in
//                        Text("\(sim.name) (\(sim.runtime))").tag(Optional(sim))
//                    }
//                }
//                .pickerStyle(.menu)
//                .padding(.horizontal)
//
//                if let sim = selectedSimulator {
//                    Button("Actualizar perfil actual") {
//                        self.activeProfile = SimulatorNetworkService.getActiveNetworkProfile(simulatorUDID: sim.udid)
//                    }
//                    .buttonStyle(.bordered)
//                    .padding(.horizontal)
//
//                    if let current = activeProfile {
//                        Text("Perfil actual: \(current)")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                            .padding(.horizontal)
//                    }
//                }
//
//                Picker("Perfil de red", selection: $selectedProfile) {
//                    ForEach(SimulatorNetworkProfile.allCases) { profile in
//                        Text(profile.label).tag(profile)
//                    }
//                }
//                .pickerStyle(.segmented)
//                .padding(.horizontal)
//                .disabled(selectedSimulator == nil)
//
//                HStack(spacing: 16) {
//                    Button("Aplicar perfil") {
//                        applyProfile()
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .disabled(selectedSimulator == nil)
//                    Button("Restablecer red") {
//                        resetProfile()
//                    }
//                    .buttonStyle(.bordered)
//                    .disabled(selectedSimulator == nil)
//                }
//                .padding(.horizontal)
//
//                if let error {
//                    Text(error)
//                        .foregroundColor(.red)
//                        .padding(.horizontal)
//                }
//            }
//
//            Spacer()
//            Text("Elige el simulador y un perfil de red para simular WiFi, LTE, 3G, Edge o red caída. Solo afecta el simulador, no tu Mac. Puedes actualizar para ver el perfil activo actual y restablecer la red a su estado normal.")
//                .font(.footnote)
//                .foregroundColor(.secondary)
//                .padding(.horizontal)
//        }
//        .onAppear(perform: loadSimulators)
//    }
//
//    func loadSimulators() {
//        isLoading = true
//        error = nil
//        Task {
//            do {
//                let all = try await DeviceService.fetchDevices()
//                let onlyBootedSims = all.filter { $0.type == .simulator && $0.state == "Booted" }
//                await MainActor.run {
//                    self.simulators = onlyBootedSims
//                    if selectedSimulator == nil { self.selectedSimulator = onlyBootedSims.first }
//                    if let sim = selectedSimulator ?? onlyBootedSims.first {
//                        self.activeProfile = SimulatorNetworkService.getActiveNetworkProfile(simulatorUDID: sim.udid)
//                    }
//                    self.isLoading = false
//                }
//            } catch {
//                await MainActor.run {
//                    self.error = error.localizedDescription
//                    self.isLoading = false
//                }
//            }
//        }
//    }
//
//    func applyProfile() {
//        guard let sim = selectedSimulator else { return }
//        do {
//            try SimulatorNetworkService.applyNetworkProfile(simulatorUDID: sim.udid, profile: selectedProfile)
//            self.error = nil
//            self.activeProfile = SimulatorNetworkService.getActiveNetworkProfile(simulatorUDID: sim.udid)
//        } catch {
//            self.error = error.localizedDescription
//        }
//    }
//
//    func resetProfile() {
//        guard let sim = selectedSimulator else { return }
//        do {
//            try SimulatorNetworkService.disableConditioner(simulatorUDID: sim.udid)
//            self.error = nil
//            self.activeProfile = SimulatorNetworkService.getActiveNetworkProfile(simulatorUDID: sim.udid)
//        } catch {
//            self.error = error.localizedDescription
//        }
//    }
//}
