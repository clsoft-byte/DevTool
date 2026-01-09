//
//  ContentView.swift
//  DevTool
//
//  Created by Cardiell on 06/01/26.
//

import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case devices, logs, network, files, location, tasks, events, recording, settings

    var id: String { rawValue }
    var label: String {
        switch self {
        case .devices: return "Dispositivos"
        case .logs: return "Logs"
        case .network: return "Red"
//        case .database: return "Base de Datos"
        case .files: return "Archivos"
        case .location: return "Ubicación"
        case .tasks: return "Tareas"
        case .events: return "Push / Eventos"
        case .recording: return "Grabación"
        case .settings: return "Ajustes"
        }
    }
    var icon: String {
        switch self {
        case .devices: return "desktopcomputer"
        case .logs: return "doc.text.magnifyingglass"
        case .network: return "network"
//        case .database: return "database"
        case .files: return "folder"
        case .location: return "location"
        case .tasks: return "tray.full"
        case .events: return "bolt.horizontal.circle"
        case .recording: return "video"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem? = .devices

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(SidebarItem.allCases) { item in
                    Button(action: { selection = item }) {
                        HStack(spacing: 12) { // Espaciado entre icono y texto
                            Image(systemName: item.icon)
                                .font(.system(size: 18, weight: .regular))
                                .frame(width: 24, height: 24)
                                .foregroundColor(selection == item ? .accentColor : .secondary)
                            Text(item.label)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selection == item ? .accentColor : .primary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.leading, 16) // Padding izquierdo para que todo se vea separado del borde
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selection == item ? Color.accentColor.opacity(0.13) : Color.clear)
                        .overlay(
                            Rectangle()
                                .fill(selection == item ? Color.accentColor : Color.clear)
                                .frame(width: 4)
                                .padding(.leading, -8),
                            alignment: .leading
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
            }
            .frame(minWidth: 210)

        } detail: {
            Group {
                switch selection {
                case .devices:   DevicesView()
                case .logs:      LogsView()
                case .network:   NetworkView()
//                case .database:  Text("Base de Datos").font(.largeTitle)
                case .files:     Text("Archivos").font(.largeTitle)
                case .location:  Text("Ubicación").font(.largeTitle)
                case .tasks:     Text("Tareas").font(.largeTitle)
                case .events:    Text("Push / Eventos").font(.largeTitle)
                case .recording: Text("Grabación").font(.largeTitle)
                case .settings:  Text("Ajustes").font(.largeTitle)
                case nil:        Text("Selecciona una sección").foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
