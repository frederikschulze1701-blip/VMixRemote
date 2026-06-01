// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct ProfileManagerView: View {
    @ObservedObject var viewModel: MixerViewModel

    var body: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.saveProfile()
            } label: {
                Label("Speichern", systemImage: "square.and.arrow.down")
            }
            .help("Profil speichern")
            .accessibilityLabel("Profil speichern")

            Button {
                viewModel.chooseAndImportProfile()
            } label: {
                Label("Importieren", systemImage: "tray.and.arrow.down")
            }
            .help("Profil importieren")
            .accessibilityLabel("Profil importieren")

            Button {
                viewModel.chooseAndExportProfile()
            } label: {
                Label("Exportieren", systemImage: "tray.and.arrow.up")
            }
            .help("Profil exportieren")
            .accessibilityLabel("Profil exportieren")

            Menu {
                Button("Gespeichertes Profil laden...", systemImage: "folder") {
                    viewModel.chooseAndLoadProfile()
                }

                Button("Erstes Profil laden", systemImage: "folder.badge.gearshape") {
                    viewModel.loadFirstAvailableProfile()
                }

                Divider()

                Button("Legacy-Profile migrieren", systemImage: "arrow.triangle.2.circlepath") {
                    viewModel.migrateLegacyProfilesFromWorkspace()
                }
            } label: {
                Label("Mehr", systemImage: "ellipsis.circle")
            }
            .help("Weitere Profilaktionen")
            .accessibilityLabel("Weitere Profilaktionen")
        }
        .labelStyle(.titleAndIcon)
    }
}
