// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import VMixMIDI

struct MIDIActivityLogView: View {
    let activityLog: [MIDIActivity]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MIDI")
                    .font(.headline)
                Spacer()
                Text("\(activityLog.count)")
                    .foregroundStyle(.secondary)
                    .font(.caption.monospacedDigit())
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            List(activityLog.suffix(160).reversed()) { activity in
                HStack(spacing: 8) {
                    Text(activity.timestamp, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 66, alignment: .leading)
                    Image(systemName: iconName(for: activity.direction))
                        .foregroundStyle(color(for: activity.direction))
                        .frame(width: 18)
                    Text(activity.bytes.hexString)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .help(activity.deviceName ?? activity.direction.rawValue)
            }
            .listStyle(.inset)
        }
    }

    private func iconName(for direction: MIDIActivityDirection) -> String {
        switch direction {
        case .incoming:
            return "arrow.down.left"
        case .outgoing:
            return "arrow.up.right"
        case .system:
            return "info.circle"
        }
    }

    private func color(for direction: MIDIActivityDirection) -> Color {
        switch direction {
        case .incoming:
            return .green
        case .outgoing:
            return .blue
        case .system:
            return .secondary
        }
    }
}
