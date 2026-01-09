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
