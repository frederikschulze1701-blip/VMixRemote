// SPDX-License-Identifier: Apache-2.0

import AppKit
import SwiftUI

@main
struct VMixRemoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = MixerViewModel()

    var body: some Scene {
        WindowGroup("VMix Remote") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 980, minHeight: 640)
        }
        .commands {
            CommandGroup(after: .saveItem) {
                Button("Save Profile") {
                    viewModel.saveProfile()
                }
                .keyboardShortcut("s", modifiers: [.command])

                Button("Load Profile") {
                    viewModel.chooseAndLoadProfile()
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button("Import Profile...") {
                    viewModel.chooseAndImportProfile()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Export Profile...") {
                    viewModel.chooseAndExportProfile()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
