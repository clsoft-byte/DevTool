//
//  NetworkView.swift
//  DevTool
//
//  Created by Cardiell on 07/01/26.
//

import SwiftUI

struct NetworkView: View {
    @StateObject private var viewModel = NetworkViewModel()
    @State private var selectedStream: NetworkStream = .live
    @AppStorage("networkOnboardingSeen") private var networkOnboardingSeen = false
    @State private var showOnboarding = false
    @State private var onboardingStep: NetworkOnboardingStep = .computerCertificate
    @State private var onboardingError: String?
    @State private var isInstallingCertificate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tráfico de Red")
                .font(.title2)
                .bold()

            connectionSection
            proxySection
            filtersSection
            sessionsSection
            streamPicker
            eventList
        }
        .padding()
        .onAppear {
            viewModel.start()
            if !networkOnboardingSeen {
                onboardingStep = .computerCertificate
                showOnboarding = true
            }
        }
        .onDisappear {
            viewModel.stop()
        }
        .sheet(isPresented: $showOnboarding) {
            NetworkOnboardingModal(
                step: $onboardingStep,
                isInstallingCertificate: isInstallingCertificate,
                errorMessage: onboardingError,
                onConfirm: {
                    networkOnboardingSeen = true
                    showOnboarding = false
                },
                onAcceptCertificate: {
                    onboardingError = nil
                    isInstallingCertificate = true
                    Task { @MainActor in
                        do {
                            try await viewModel.installCertificate()
                            onboardingStep = .mobileSetup
                        } catch {
                            onboardingError = error.localizedDescription
                        }
                        isInstallingCertificate = false
                    }
                },
                onCancel: {
                    showOnboarding = false
                }
            )
            .interactiveDismissDisabled()
        }
    }

    private var connectionSection: some View {
        HStack {
            TextField("Host", text: $viewModel.host)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
            TextField("Puerto", text: $viewModel.port)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
            Button("Conectar") {
                viewModel.connectWebSocket()
                Task {
                    await viewModel.refreshStatus()
                    await viewModel.refreshFilters()
                }
            }
            Spacer()
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
    }

    private var proxySection: some View {
        HStack(spacing: 12) {
            Text("Proxy:")
                .font(.headline)
            Text(viewModel.proxyEnabled ? "Habilitado" : "Deshabilitado")
                .foregroundColor(viewModel.proxyEnabled ? .green : .secondary)
            Button("Iniciar") {
                Task { await viewModel.startProxy() }
            }
            .disabled(viewModel.proxyEnabled)
            Button("Detener") {
                Task { await viewModel.stopProxy() }
            }
            .disabled(!viewModel.proxyEnabled)
            Button("Actualizar estado") {
                Task { await viewModel.refreshStatus() }
            }
            Spacer()
        }
    }

    private var filtersSection: some View {
        DisclosureGroup("Filtros") {
            VStack(alignment: .leading, spacing: 8) {
                filterField(title: "Include hosts", binding: stringArrayBinding(\.includeHosts))
                filterField(title: "Exclude hosts", binding: stringArrayBinding(\.excludeHosts))
                filterField(title: "Include methods", binding: stringArrayBinding(\.includeMethods))
                filterField(title: "Exclude methods", binding: stringArrayBinding(\.excludeMethods))
                filterField(title: "Include status codes", binding: intArrayBinding(\.includeStatusCodes))
                filterField(title: "Exclude status codes", binding: intArrayBinding(\.excludeStatusCodes))
                filterField(title: "Include URL contains", binding: stringArrayBinding(\.includeUrlContains))
                filterField(title: "Exclude URL contains", binding: stringArrayBinding(\.excludeUrlContains))

                HStack {
                    Button("Cargar filtros") {
                        Task { await viewModel.refreshFilters() }
                    }
                    Button("Guardar filtros") {
                        Task { await viewModel.saveFilters() }
                    }
                    Spacer()
                }
                .padding(.top, 6)
            }
            .padding(.top, 8)
        }
    }

    private var sessionsSection: some View {
        HStack {
            Text("Sesiones persistidas: \(viewModel.sessions.count)")
                .font(.headline)
            Button("Cargar sesiones") {
                Task { await viewModel.refreshSessions() }
            }
            Button("Borrar sesiones") {
                Task { await viewModel.clearSessions() }
            }
            Spacer()
        }
    }

    private var streamPicker: some View {
        Picker("Fuente", selection: $selectedStream) {
            ForEach(NetworkStream.allCases) { stream in
                Text(stream.label).tag(stream)
            }
        }
        .pickerStyle(.segmented)
    }

    private var eventList: some View {
        let events = selectedStream == .live ? viewModel.events : viewModel.sessions
        return List(events) { event in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.type.capitalized)
                        .font(.headline)
                        .foregroundColor(event.type == "request" ? .blue : .green)
                    if let time = event.time {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

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

    private func filterField(title: String, binding: Binding<String>) -> some View {
        HStack {
            Text(title)
                .frame(width: 180, alignment: .leading)
            TextField("Separado por comas", text: binding)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func stringArrayBinding(_ keyPath: WritableKeyPath<NetworkTrafficService.NetworkFilters, [String]>) -> Binding<String> {
        Binding(
            get: { viewModel.filters[keyPath: keyPath].joined(separator: ", ") },
            set: { viewModel.filters[keyPath: keyPath] = parseStringArray($0) }
        )
    }

    private func intArrayBinding(_ keyPath: WritableKeyPath<NetworkTrafficService.NetworkFilters, [Int]>) -> Binding<String> {
        Binding(
            get: { viewModel.filters[keyPath: keyPath].map(String.init).joined(separator: ", ") },
            set: { viewModel.filters[keyPath: keyPath] = parseIntArray($0) }
        )
    }

    private func parseStringArray(_ value: String) -> [String] {
        value.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parseIntArray(_ value: String) -> [Int] {
        parseStringArray(value).compactMap { Int($0) }
    }
}

private enum NetworkStream: String, CaseIterable, Identifiable {
    case live
    case sessions

    var id: String { rawValue }

    var label: String {
        switch self {
        case .live:
            return "Live"
        case .sessions:
            return "Sesiones"
        }
    }
}

private enum NetworkOnboardingStep {
    case computerCertificate
    case mobileSetup
}

private struct NetworkOnboardingModal: View {
    @Binding var step: NetworkOnboardingStep
    let isInstallingCertificate: Bool
    let errorMessage: String?
    let onConfirm: () -> Void
    let onAcceptCertificate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()

            Text(description)
                .font(.body)

            if step == .computerCertificate {
                Text("Para continuar necesitas instalar el certificado en este ordenador. Si no lo instalas, no podrás ver el tráfico de simuladores de iOS, emuladores de Android o dispositivos físicos, porque el tráfico pasa por la computadora.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundColor(.red)
            }

            Spacer()

            HStack {
                if step == .computerCertificate {
                    Button("Cancelar") {
                        onCancel()
                    }
                    .keyboardShortcut(.cancelAction)

                    Button(isInstallingCertificate ? "Instalando..." : "Aceptar") {
                        onAcceptCertificate()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(isInstallingCertificate)
                } else {
                    Button("Confirmar") {
                        onConfirm()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding()
        .frame(minWidth: 420, minHeight: 240)
    }

    private var title: String {
        switch step {
        case .computerCertificate:
            return "Instala el certificado"
        case .mobileSetup:
            return "Instala en iOS o Android"
        }
    }

    private var description: String {
        switch step {
        case .computerCertificate:
            return "El certificado permite inspeccionar el tráfico de red de tus dispositivos."
        case .mobileSetup:
            return "Ahora instala el certificado en iOS o Android siguiendo las instrucciones correspondientes. Cuando termines, pulsa Confirmar."
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
