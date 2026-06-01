// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct KnobView: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var formatter: (Double) -> String = { String(format: "%.1f", $0) }

    private let startAngle = -135.0
    private let endAngle = 135.0

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                Circle()
                    .stroke(.secondary.opacity(0.25), lineWidth: 1)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 3, height: 16)
                    .offset(y: -10)
                    .rotationEffect(.degrees(angle))
            }
            .frame(width: 52, height: 52)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let delta = Double(-gesture.translation.height + gesture.translation.width) * 0.005
                        let span = range.upperBound - range.lowerBound
                        let nextValue = value + span * delta
                        value = nextValue.clamped(to: range)
                    }
            )

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(formatter(value))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 72)
    }

    private var angle: Double {
        let normalized = ((value - range.lowerBound) / (range.upperBound - range.lowerBound)).clamped(to: 0.0...1.0)
        return startAngle + (endAngle - startAngle) * normalized
    }
}
