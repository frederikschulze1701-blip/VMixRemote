// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct MixerModel: Codable, Equatable, Sendable {
    public var channels: [Channel]

    public init(channels: [Channel]) {
        self.channels = channels
    }

    public init(channelCount: Int = 8) {
        let count = max(1, channelCount)
        self.channels = (0..<count).map { index in
            Channel(
                channelID: ChannelID(kind: .input, index: index),
                isSelected: index == 0
            )
        }
    }

    public var selectedChannelID: ChannelID? {
        channels.first(where: \.isSelected)?.channelID
    }

    public var selectedChannel: Channel? {
        guard let selectedChannelID else { return channels.first }
        return channels.first { $0.channelID == selectedChannelID }
    }

    public func channel(for id: ChannelID) throws -> Channel {
        guard let channel = channels.first(where: { $0.channelID == id }) else {
            throw MixerCoreError.invalidChannelIndex(id.index)
        }
        return channel
    }

    public mutating func update(_ update: MixerParameterUpdate) throws {
        try setParameter(update.address, to: update.value)
    }

    public mutating func setParameter(_ address: MixerParameterAddress, to value: MixerParameterValue) throws {
        guard let channelIndex = channels.firstIndex(where: { $0.channelID == address.channelID }) else {
            throw MixerCoreError.invalidChannelIndex(address.channelID.index)
        }

        switch address.kind {
        case .fader:
            guard let doubleValue = value.doubleValue else {
                throw MixerCoreError.invalidParameterValue("Fader expects a Double value.")
            }
            channels[channelIndex].fader.setNormalized(doubleValue)
        case .mute:
            guard let boolValue = value.boolValue else {
                throw MixerCoreError.invalidParameterValue("Mute expects a Bool value.")
            }
            channels[channelIndex].isMuted = boolValue
        case .solo:
            guard let boolValue = value.boolValue else {
                throw MixerCoreError.invalidParameterValue("Solo expects a Bool value.")
            }
            channels[channelIndex].isSolo = boolValue
        case .select:
            guard let boolValue = value.boolValue else {
                throw MixerCoreError.invalidParameterValue("Select expects a Bool value.")
            }
            if boolValue {
                for index in channels.indices {
                    channels[index].isSelected = false
                }
            }
            channels[channelIndex].isSelected = boolValue
        case .pan:
            guard let doubleValue = value.doubleValue else {
                throw MixerCoreError.invalidParameterValue("Pan expects a Double value.")
            }
            channels[channelIndex].pan = doubleValue
        case .eqFrequency, .eqGain, .eqQ:
            guard let bandIndex = address.eqBandIndex,
                  channels[channelIndex].eqBands.indices.contains(bandIndex) else {
                throw MixerCoreError.invalidParameterValue("EQ parameter requires a valid band index.")
            }
            guard let doubleValue = value.doubleValue else {
                throw MixerCoreError.invalidParameterValue("EQ parameter expects a Double value.")
            }
            switch address.kind {
            case .eqFrequency:
                channels[channelIndex].eqBands[bandIndex].frequency = doubleValue
            case .eqGain:
                channels[channelIndex].eqBands[bandIndex].gainDecibels = doubleValue
            case .eqQ:
                channels[channelIndex].eqBands[bandIndex].q = doubleValue
            default:
                break
            }
        }
    }

    public func parameterValue(for address: MixerParameterAddress) throws -> MixerParameterValue {
        let channel = try channel(for: address.channelID)
        switch address.kind {
        case .fader:
            return .double(channel.fader.normalized)
        case .mute:
            return .bool(channel.isMuted)
        case .solo:
            return .bool(channel.isSolo)
        case .select:
            return .bool(channel.isSelected)
        case .pan:
            return .double(channel.pan)
        case .eqFrequency, .eqGain, .eqQ:
            guard let bandIndex = address.eqBandIndex,
                  channel.eqBands.indices.contains(bandIndex) else {
                throw MixerCoreError.invalidParameterValue("EQ parameter requires a valid band index.")
            }
            switch address.kind {
            case .eqFrequency:
                return .double(channel.eqBands[bandIndex].frequency)
            case .eqGain:
                return .double(channel.eqBands[bandIndex].gainDecibels)
            case .eqQ:
                return .double(channel.eqBands[bandIndex].q)
            default:
                throw MixerCoreError.invalidParameterValue("Unsupported EQ parameter.")
            }
        }
    }
}
