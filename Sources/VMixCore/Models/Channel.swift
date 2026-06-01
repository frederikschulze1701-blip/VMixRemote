// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct Channel: Codable, Identifiable, Equatable, Sendable {
    public var channelID: ChannelID
    public var name: String
    public var fader: FaderValue
    public var isMuted: Bool
    public var isSolo: Bool
    public var isSelected: Bool
    public var pan: Double {
        didSet { pan = pan.clamped(to: -1.0...1.0) }
    }
    public var eqBands: [EQBand]

    public var id: ChannelID {
        channelID
    }

    public init(
        channelID: ChannelID,
        name: String? = nil,
        fader: FaderValue = FaderValue(),
        isMuted: Bool = false,
        isSolo: Bool = false,
        isSelected: Bool = false,
        pan: Double = 0,
        eqBands: [EQBand] = EQBand.defaultBands()
    ) {
        self.channelID = channelID
        self.name = name ?? Self.defaultName(for: channelID)
        self.fader = fader
        self.isMuted = isMuted
        self.isSolo = isSolo
        self.isSelected = isSelected
        self.pan = pan.clamped(to: -1.0...1.0)
        self.eqBands = eqBands
    }

    public static func defaultName(for channelID: ChannelID) -> String {
        switch channelID.kind {
        case .input:
            return "CH \(channelID.index + 1)"
        case .aux:
            return "AUX \(channelID.index + 1)"
        case .bus:
            return "BUS \(channelID.index + 1)"
        case .stereo:
            return "STEREO"
        case .dca:
            return "DCA \(channelID.index + 1)"
        }
    }
}
