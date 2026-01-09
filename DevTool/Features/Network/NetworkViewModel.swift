//
//  NetworkViewModel.swift
//  DevTool
//
//  Created by Cardiell on 07/01/26.
//

import Foundation
import Combine

@MainActor
final class NetworkViewModel: ObservableObject {

    @Published var events: [NetworkEvent] = []
    @Published var sessions: [NetworkEvent] = []
    @Published var proxyEnabled = false
    @Published var filters = NetworkTrafficService.NetworkFilters()
    @Published var host = "localhost"
    @Published var port = "9999"
    @Published var errorMessage: String?

    private let service = NetworkTrafficService()
    private var cancellables = Set<AnyCancellable>()

    func start() {
        service.$events
            .receive(on: DispatchQueue.main)
            .assign(to: &$events)

        service.connect(host: host, port: portValue)
        Task {
            await refreshStatus()
            await refreshFilters()
        }
    }

    func stop() {
        service.disconnect()
    }

    func connectWebSocket() {
        service.disconnect()
        service.connect(host: host, port: portValue)
    }

    func refreshStatus() async {
        do {
            let status = try await service.fetchProxyStatus(
                host: host,
                port: portValue
            )
            proxyEnabled = status.enabled
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    func startProxy() async {
        do {
            let status = try await service.startProxy(
                host: host,
                port: portValue
            )
            proxyEnabled = status.enabled
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    func stopProxy() async {
        do {
            let status = try await service.stopProxy(
                host: host,
                port: portValue
            )
            proxyEnabled = status.enabled
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    func refreshFilters() async {
        do {
            filters = try await service.fetchFilters(
                host: host,
                port: portValue
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    func saveFilters() async {
        do {
            filters = try await service.updateFilters(
                filters,
                host: host,
                port: portValue
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshSessions() async {
        do {
            sessions = try await service.fetchSessions(
                host: host,
                port: portValue
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    func clearSessions() async {
        do {
            try await service.clearSessions(
                host: host,
                port: portValue
            )
            sessions = []
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func installCertificate() async throws {
        try await CertificateInstaller.installCertificate(host: host, port: portValue)
    }

    private var portValue: Int {
        Int(port) ?? 9999
    }

    private func perform(_ work: @escaping @Sendable () async throws -> Void) async {
        do {
            try await work()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
