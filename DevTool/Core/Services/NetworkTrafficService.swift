//
//  NetworkTrafficService.swift
//  DevTool
//
//  Created by Cardiell on 07/01/26.
//

import Foundation
import Combine

final class NetworkTrafficService: ObservableObject {
    @Published var events: [NetworkEvent] = []
    private var task: URLSessionWebSocketTask?

    func connect(host: String = "localhost", port: Int = 9999) {
        guard task == nil else { return }
        let url = URL(string: "ws://\(host):\(port)/ws")!
        task = URLSession(configuration: .default).webSocketTask(with: url)
        task?.resume()
        listen()
    }

    func disconnect() {
        task?.cancel()
        task = nil
    }

    private func listen() {
        task?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let json) = message,
                   let data = json.data(using: .utf8),
                   let event = try? JSONDecoder().decode(NetworkEvent.self, from: data) {
                    DispatchQueue.main.async {
                        self?.events.insert(event, at: 0) // Último primero
                    }
                }
            case .failure(let error):
                print("WebSocket error: \(error)")
            }
            self?.listen()
        }
    }
}

extension NetworkTrafficService {
    struct ProxyStatus: Decodable {
        let enabled: Bool
    }

    struct NetworkFilters: Codable, Equatable {
        var includeHosts: [String] = []
        var excludeHosts: [String] = []
        var includeMethods: [String] = []
        var excludeMethods: [String] = []
        var includeStatusCodes: [Int] = []
        var excludeStatusCodes: [Int] = []
        var includeUrlContains: [String] = []
        var excludeUrlContains: [String] = []

        enum CodingKeys: String, CodingKey {
            case includeHosts = "include_hosts"
            case excludeHosts = "exclude_hosts"
            case includeMethods = "include_methods"
            case excludeMethods = "exclude_methods"
            case includeStatusCodes = "include_status_codes"
            case excludeStatusCodes = "exclude_status_codes"
            case includeUrlContains = "include_url_contains"
            case excludeUrlContains = "exclude_url_contains"
        }
    }

    enum NetworkTrafficError: LocalizedError {
        case invalidResponse
        case httpError(status: Int)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Respuesta inválida del servidor."
            case .httpError(let status):
                return "Error HTTP \(status)."
            }
        }
    }

    func fetchProxyStatus(host: String = "localhost", port: Int = 9999) async throws -> ProxyStatus {
        try await request(host: host, port: port, path: "/proxy/status", method: "GET")
    }

    func startProxy(host: String = "localhost", port: Int = 9999) async throws -> ProxyStatus {
        try await request(host: host, port: port, path: "/proxy/start", method: "POST")
    }

    func stopProxy(host: String = "localhost", port: Int = 9999) async throws -> ProxyStatus {
        try await request(host: host, port: port, path: "/proxy/stop", method: "POST")
    }

    func fetchFilters(host: String = "localhost", port: Int = 9999) async throws -> NetworkFilters {
        try await request(host: host, port: port, path: "/filters", method: "GET")
    }

    func updateFilters(_ filters: NetworkFilters, host: String = "localhost", port: Int = 9999) async throws -> NetworkFilters {
        let encoder = JSONEncoder()
        let body = try encoder.encode(filters)
        return try await request(host: host, port: port, path: "/filters", method: "PUT", body: body)
    }

    func fetchSessions(host: String = "localhost", port: Int = 9999) async throws -> [NetworkEvent] {
        try await request(host: host, port: port, path: "/sessions", method: "GET")
    }

    func clearSessions(host: String = "localhost", port: Int = 9999) async throws {
        _ = try await requestVoid(host: host, port: port, path: "/sessions", method: "DELETE")
    }

    private func request<T: Decodable>(host: String, port: Int, path: String, method: String, body: Data? = nil) async throws -> T {
        let url = makeURL(host: host, port: port, path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkTrafficError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkTrafficError.httpError(status: httpResponse.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func requestVoid(host: String, port: Int, path: String, method: String, body: Data? = nil) async throws {
        let url = makeURL(host: host, port: port, path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkTrafficError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkTrafficError.httpError(status: httpResponse.statusCode)
        }
    }

    private func makeURL(host: String, port: Int, path: String) -> URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = port
        components.path = path
        return components.url!
    }
}
