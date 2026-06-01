// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import VMixCore

struct ContentView: View {
    @ObservedObject var viewModel: MixerViewModel

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            HSplitView {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(viewModel.mixer.channels) { channel in
                            ChannelStripView(
                                channel: channel,
                                faderValue: Binding(
                                    get: { currentChannel(channel.channelID)?.fader.normalized ?? channel.fader.normalized },
                                    set: { viewModel.setFader(channelID: channel.channelID, normalizedValue: $0) }
                                ),
                                muteAction: { viewModel.setMute(channelID: channel.channelID, isMuted: !channel.isMuted) },
                                soloAction: { viewModel.setSolo(channelID: channel.channelID, isSolo: !channel.isSolo) },
                                selectAction: { viewModel.select(channelID: channel.channelID) }
                            )
                        }
                    }
                    .padding(14)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(minWidth: 660, maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 0) {
                    EQEditorView(viewModel: viewModel)
                        .frame(minHeight: 220, idealHeight: 260, maxHeight: 320)
                    Divider()
                    MIDIActivityLogView(activityLog: viewModel.activityLog)
                }
                .frame(minWidth: 320, idealWidth: 380, maxWidth: 460)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                DevicePickerView(viewModel: viewModel)
            }
        }
        .alert(item: $viewModel.presentedError) { error in
            Alert(
                title: Text("Fehler"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Text(viewModel.profile.name)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Text(viewModel.statusMessage)
                .foregroundStyle(.secondary)
                .font(.callout)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            ProfileManagerView(viewModel: viewModel)
                .controlSize(.small)
            Text("\(viewModel.mixer.channels.count) Channels")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func currentChannel(_ id: ChannelID) -> Channel? {
        viewModel.mixer.channels.first { $0.channelID == id }
    }
}
