// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct MixerFaderView: View {
    @Binding var value: Double

    private let knobHeight = 26.0
    private let trackWidth = 7.0

    var body: some View {
        GeometryReader { geometry in
            let availableHeight = max(1, geometry.size.height - knobHeight)
            let knobY = (1.0 - value.clamped(to: 0.0...1.0)) * availableHeight + knobHeight / 2

            ZStack {
                Capsule()
                    .fill(.quaternary)
                    .frame(width: trackWidth)

                VStack {
                    Spacer(minLength: 0)
                    Capsule()
                        .fill(Color.accentColor.opacity(0.72))
                        .frame(width: trackWidth, height: geometry.size.height * value.clamped(to: 0.0...1.0))
                }

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(.secondary.opacity(0.28), lineWidth: 1)
                    }
                    .frame(width: 44, height: knobHeight)
                    .position(x: geometry.size.width / 2, y: knobY)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let raw = 1.0 - ((gesture.location.y - knobHeight / 2) / availableHeight)
                        value = raw.clamped(to: 0.0...1.0)
                    }
            )
        }
        .accessibilityLabel("Fader")
    }
}
