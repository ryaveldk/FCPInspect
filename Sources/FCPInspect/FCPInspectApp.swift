import SwiftUI
import AppKit

@main
struct FCPInspectApp: App {
    @StateObject private var state = AppState()

    init() {
        // SwiftPM-built mac apps don't get the usual Info.plist activation
        // treatment, so we have to opt in explicitly to get a proper
        // window and Dock presence.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup("FCPInspect") {
            ContentView()
                .environmentObject(state)
                .frame(minWidth: 960, minHeight: 580)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") { state.presentOpenPanel() }
                    .keyboardShortcut("o")
            }
            CommandGroup(after: .newItem) {
                Button("Clear All Sources") { state.clearAll() }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    .disabled(state.isEmpty)
            }
        }
    }
}
