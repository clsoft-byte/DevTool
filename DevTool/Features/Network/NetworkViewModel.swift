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

    private let service = NetworkTrafficService()
    private var cancellables = Set<AnyCancellable>()

    func start() {
        service.$events
            .receive(on: DispatchQueue.main)
            .assign(to: &$events)

        service.connect()
    }

    func stop() {
        service.disconnect()
    }
}
