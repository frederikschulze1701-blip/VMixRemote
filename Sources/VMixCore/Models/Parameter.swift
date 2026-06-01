// SPDX-License-Identifier: Apache-2.0

import Foundation

public enum ChannelKind: String, Codable, CaseIterable, Sendable {
    case input
    case aux
    case bus
    case stereo
    case dca
}

public struct ChannelID: Codable, Hashable, Identifiable, Comparable, Sendable {
    public var kind: ChannelKind
    public var index: Int

    public var id: String {
        "\(kind.rawValue)-\(index)"
    }

    public init(kind: ChannelKind = .input, index: Int) {
        self.kind = kind
        self.index = index
    }

    public static func < (lhs: ChannelID, rhs: ChannelID) -> Bool {
        if lhs.kind.rawValue == rhs.kind.rawValue {
            return lhs.index < rhs.index
        }
        return lhs.kind.rawValue < rhs.kind.rawValue
    }
}

public enum ParameterKind: String, Codable, CaseIterable, Sendable {
    case fader
    case mute
    case solo
    case select
    case pan
    case eqFrequency
    case eqGain
    case eqQ
}

public struct MixerParameterAddress: Codable, Hashable, Identifiable, Sendable {
    public var channelID: ChannelID
    public var kind: ParameterKind
    public var eqBandIndex: Int?

    public var id: String {
        if let eqBandIndex {
            return "\(channelID.id)-\(kind.rawValue)-\(eqBandIndex)"
        }
        return "\(channelID.id)-\(kind.rawValue)"
    }

    public init(channelID: ChannelID, kind: ParameterKind, eqBandIndex: Int? = nil) {
        self.channelID = channelID
        self.kind = kind
        self.eqBandIndex = eqBandIndex
    }
}

public enum MixerParameterValue: Codable, Equatable, Sendable {
    case double(Double)
    case bool(Bool)

    public var doubleValue: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }
}

public struct MixerParameterUpdate: Codable, Equatable, Sendable {
    public var address: MixerParameterAddress
    public var value: MixerParameterValue

    public init(address: MixerParameterAddress, value: MixerParameterValue) {
        self.address = address
        self.value = value
    }
}
