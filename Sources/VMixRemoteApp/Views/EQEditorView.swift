// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import VMixCore

struct EQEditorView: View {
    @ObservedObject var viewModel: MixerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(selectedChannel?.name ?? "EQ")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "waveform.path")
                    .foregroundStyle(.secondary)
            }

            if let channel = selectedChannel {
                ScrollView(.horizontal) {
                    HStack(spacing: 14) {
                        ForEach(Array(channel.eqBands.enumerated()), id: \.element.id) { index, band in
                            VStack(spacing: 8) {
                                Text("B\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 6) {
                                    KnobView(
                                        title: "Hz",
                                        value: binding(channelID: channel.channelID, bandIndex: index, kind: .eqFrequency, fallback: band.frequency),
                                        range: EQBand.frequencyRange,
                                        formatter: frequencyFormatter
                                    )
                                    KnobView(
                                        title: "Gain",
                                        value: binding(channelID: channel.channelID, bandIndex: index, kind: .eqGain, fallback: band.gainDecibels),
                                        range: EQBand.gainRange,
                                        formatter: { String(format: "%+.1f", $0) }
                                    )
                                    KnobView(
                                        title: "Q",
                                        value: binding(channelID: channel.channelID, bandIndex: index, kind: .eqQ, fallback: band.q),
                                        range: EQBand.qRange,
                                        formatter: { String(format: "%.2f", $0) }
                                    )
                                }
                            }
                            .padding(8)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
        .padding(12)
    }

    private var selectedChannel: Channel? {
        viewModel.mixer.selectedChannel
    }

    private func binding(channelID: ChannelID, bandIndex: Int, kind: ParameterKind, fallback: Double) -> Binding<Double> {
        Binding(
            get: {
                guard let channel = viewModel.mixer.channels.first(where: { $0.channelID == channelID }),
                      channel.eqBands.indices.contains(bandIndex) else {
                    return fallback
                }
                let band = channel.eqBands[bandIndex]
                switch kind {
                case .eqFrequency:
                    return band.frequency
                case .eqGain:
                    return band.gainDecibels
                case .eqQ:
                    return band.q
                default:
                    return fallback
                }
            },
            set: { viewModel.setEQ(channelID: channelID, bandIndex: bandIndex, kind: kind, value: $0) }
        )
    }

    private func frequencyFormatter(_ value: Double) -> String {
        if value >= 1_000 {
            return String(format: "%.1fk", value / 1_000)
        }
        return String(format: "%.0f", value)
    }
}
