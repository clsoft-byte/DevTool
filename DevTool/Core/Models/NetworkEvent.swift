//
//  NetworkEvent.swift
//  DevTool
//
//  Created by Cardiell on 07/01/26.
//

import Foundation

struct NetworkEvent: Identifiable, Decodable {
    let id: UUID
    let type: String
    let srcIP: String?
    let request: RequestData?
    let response: ResponseData?

    enum CodingKeys: String, CodingKey {
        case type
        case srcIP = "src_ip"
        case request
        case response
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = UUID() // 👈 generado localmente (clave)
        self.type = try container.decode(String.self, forKey: .type)
        self.srcIP = try container.decodeIfPresent(String.self, forKey: .srcIP)
        self.request = try container.decodeIfPresent(RequestData.self, forKey: .request)
        self.response = try container.decodeIfPresent(ResponseData.self, forKey: .response)
    }
}

struct RequestData: Decodable {
    let method: String
    let url: String
    let header: [String: [String]]
    let body: String?
}

struct ResponseData: Decodable {
    let status: String
    let statusCode: Int
    let header: [String: [String]]
    let body: String?

    enum CodingKeys: String, CodingKey {
        case status
        case statusCode = "status_code"
        case header
        case body
    }
}
