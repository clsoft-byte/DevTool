//
//  LogsView.swift
//  DevTool
//
//  Created by Cardiell on 06/01/26.
//

import SwiftUI

struct LogEntry: Identifiable {
    let id = UUID()
    let time: String
    let level: String
    let message: String
}


struct LogsView: View {
    @State private var logs: [LogEntry] = []
    @State private var filter: String = ""

    var body: some View {
        VStack {
            HStack {
                Text("Logs").font(.title2).bold()
                Spacer()
                Button("Exportar Log") {
                    exportLogs()
                }
            }
            .padding(.horizontal)

            TextField("Filtrar por mensaje o nivel", text: $filter)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            if logs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No hay logs para mostrar.")
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(filteredLogs) {
                    TableColumn("Hora", value: \.time)
                    TableColumn("Nivel") { entry in
                        Text(entry.level)
                            .foregroundColor(color(for: entry.level))
                            .bold()
                    }
                    TableColumn("Mensaje", value: \.message)
                }
            }
        }
        .padding()
    }

    var filteredLogs: [LogEntry] {
        if filter.isEmpty { return logs }
        return logs.filter { $0.message.localizedCaseInsensitiveContains(filter) || $0.level.localizedCaseInsensitiveContains(filter) }
    }

    func color(for level: String) -> Color {
        switch level {
        case "ERROR": return .red
        case "WARN": return .orange
        case "INFO": return .blue
        case "DEBUG": return .gray
        default: return .primary
        }
    }

    func exportLogs() {
        // Aquí puedes implementar la exportación a archivo si ya tienes logs
        print("Exportando logs:", logs.map { $0.message })
    }
}
