// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import VMixCore

struct ChannelStripView: View {
    let channel: Channel
    @Binding var faderValue: Double
    let muteAction: () -> Void
    let soloAction: () -> Void
    let selectAction: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                Text(channel.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(String(format: "%+.1f dB", channel.fader.decibels))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(height: 42)

            levelMeter
                .frame(width: 12, height: 92)

            MixerFaderView(value: $faderValue)
                .frame(width: 48, height: 230)

            HStack(spacing: 6) {
                toggleButton(
                    systemName: channel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                    isActive: channel.isMuted,
                    help: "Mute",
                    action: muteAction
                )
                toggleButton(
                    systemName: "headphones",
                    isActive: channel.isSolo,
                    help: "Solo",
                    action: soloAction
                )
            }

            Button(action: selectAction) {
                Image(systemName: channel.isSelected ? "checkmark.circle.fill" : "circle")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(channel.isSelected ? Color.accentColor : Color.secondary)
            .help("Select")
            .accessibilityLabel("Select \(channel.name)")
        }
        .padding(8)
        .frame(width: 92)
        .frame(minHeight: 430)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(channel.isSelected ? Color.accentColor.opacity(0.75) : Color.secondary.opacity(0.18), lineWidth: channel.isSelected ? 1.5 : 1)
        }
    }

    private var levelMeter: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(channel.isMuted ? Color.secondary.opacity(0.35) : Color.green.opacity(0.75))
                    .frame(height: max(4, geometry.size.height * channel.fader.normalized))
            }
        }
        .accessibilityLabel("Meter")
    }

    private func toggleButton(
        systemName: String,
        isActive: Bool,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
        .background(isActive ? Color.accentColor.opacity(0.16) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .help(help)
        .accessibilityLabel("\(help) \(channel.name)")
    }
}
