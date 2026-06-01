// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct DevicePickerView: View {
    @ObservedObject var viewModel: MixerViewModel

    var body: some View {
        HStack(spacing: 8) {
            Picker("Backend", selection: Binding(
                get: { viewModel.backendMode },
                set: { viewModel.switchBackend(to: $0) }
            )) {
                ForEach(MIDIBackendMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .frame(width: 118)
            .labelsHidden()

            Picker("Input", selection: $viewModel.selectedInputID) {
                Text("Input").tag(Optional<String>.none)
                ForEach(viewModel.inputDevices) { device in
                    Text(device.name).tag(Optional(device.id))
                }
            }
            .frame(width: 150)
            .labelsHidden()
            .onChange(of: viewModel.selectedInputID) { _ in
                viewModel.connectSelectedDevices()
            }

            Picker("Output", selection: $viewModel.selectedOutputID) {
                Text("Output").tag(Optional<String>.none)
                ForEach(viewModel.outputDevices) { device in
                    Text(device.name).tag(Optional(device.id))
                }
            }
            .frame(width: 150)
            .labelsHidden()
            .onChange(of: viewModel.selectedOutputID) { _ in
                viewModel.connectSelectedDevices()
            }

            Button {
                viewModel.refreshDevices()
            } label: {
                Label("Aktualisieren", systemImage: "arrow.clockwise")
            }
            .help("Refresh MIDI Devices")
            .labelStyle(.iconOnly)
            .accessibilityLabel("MIDI-Geräte aktualisieren")

            Button {
                viewModel.simulateMockFaderMove()
            } label: {
                Label("Mock MIDI", systemImage: "waveform.path.ecg")
            }
            .disabled(viewModel.backendMode != .mock)
            .help("Simulate MIDI Input")
            .labelStyle(.iconOnly)
            .accessibilityLabel("Mock-MIDI-Eingang simulieren")
        }
    }
}
