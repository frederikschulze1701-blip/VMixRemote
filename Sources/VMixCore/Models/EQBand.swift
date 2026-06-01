// SPDX-License-Identifier: Apache-2.0

import Foundation

public enum EQBandShape: String, Codable, CaseIterable, Sendable {
    case peak
    case shelf
    case cut
}

public struct EQBand: Codable, Identifiable, Equatable, Sendable {
    public static let frequencyRange = 20.0...20_000.0
    public static let gainRange = -18.0...18.0
    public static let qRange = 0.1...10.0

    public var id: Int
    public var shape: EQBandShape
    public var frequency: Double {
        didSet { frequency = frequency.clamped(to: Self.frequencyRange) }
    }
    public var gainDecibels: Double {
        didSet { gainDecibels = gainDecibels.clamped(to: Self.gainRange) }
    }
    public var q: Double {
        didSet { q = q.clamped(to: Self.qRange) }
    }

    public init(
        id: Int,
        shape: EQBandShape = .peak,
        frequency: Double,
        gainDecibels: Double = 0,
        q: Double = 1
    ) {
        self.id = id
        self.shape = shape
        self.frequency = frequency.clamped(to: Self.frequencyRange)
        self.gainDecibels = gainDecibels.clamped(to: Self.gainRange)
        self.q = q.clamped(to: Self.qRange)
    }

    public static func defaultBands() -> [EQBand] {
        [
            EQBand(id: 0, shape: .shelf, frequency: 80, gainDecibels: 0, q: 0.7),
            EQBand(id: 1, shape: .peak, frequency: 400, gainDecibels: 0, q: 1.0),
            EQBand(id: 2, shape: .peak, frequency: 2_500, gainDecibels: 0, q: 1.0),
            EQBand(id: 3, shape: .shelf, frequency: 10_000, gainDecibels: 0, q: 0.7)
        ]
    }
}
