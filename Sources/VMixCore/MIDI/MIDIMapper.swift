// SPDX-License-Identifier: Apache-2.0

import Foundation

public enum MIDIMappingMessageKind: String, Codable, Sendable {
    case controlChange
    case note
}

public struct MIDIValueRange: Codable, Equatable, Sendable {
    public var minimum: Double
    public var maximum: Double

    public init(minimum: Double = 0, maximum: Double = 1) {
        self.minimum = minimum
        self.maximum = maximum
    }

    public func value(from midiValue: UInt8) -> Double {
        let normalized = Double(midiValue.clamped(to: 0...127)) / 127.0
        return minimum + (maximum - minimum) * normalized
    }

    public func midiValue(from value: Double) -> UInt8 {
        guard maximum != minimum else { return 0 }
        let normalized = ((value - minimum) / (maximum - minimum)).clamped(to: 0.0...1.0)
        return UInt8((normalized * 127.0).rounded())
    }
}

public struct MIDIMapping: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var address: MixerParameterAddress
    public var messageKind: MIDIMappingMessageKind
    public var midiChannel: UInt8
    public var number: UInt8
    public var valueRange: MIDIValueRange

    public init(
        id: UUID = UUID(),
        address: MixerParameterAddress,
        messageKind: MIDIMappingMessageKind,
        midiChannel: UInt8 = 0,
        number: UInt8,
        valueRange: MIDIValueRange = MIDIValueRange()
    ) {
        self.id = id
        self.address = address
        self.messageKind = messageKind
        self.midiChannel = midiChannel.clamped(to: 0...15)
        self.number = number.clamped(to: 0...127)
        self.valueRange = valueRange
    }
}

public struct MIDIMapper: Codable, Equatable, Sendable {
    public var mappings: [MIDIMapping]

    public init(mappings: [MIDIMapping] = []) {
        self.mappings = mappings
    }

    public static func defaultChannelStripMapper(channelCount: Int) -> MIDIMapper {
        let count = max(1, channelCount)
        var mappings: [MIDIMapping] = []
        for index in 0..<count {
            let channelID = ChannelID(kind: .input, index: index)
            mappings.append(MIDIMapping(
                address: MixerParameterAddress(channelID: channelID, kind: .fader),
                messageKind: .controlChange,
                midiChannel: 0,
                number: UInt8(index.clamped(to: 0...127))
            ))
            mappings.append(MIDIMapping(
                address: MixerParameterAddress(channelID: channelID, kind: .mute),
                messageKind: .note,
                midiChannel: 0,
                number: UInt8((16 + index).clamped(to: 0...127))
            ))
            mappings.append(MIDIMapping(
                address: MixerParameterAddress(channelID: channelID, kind: .solo),
                messageKind: .note,
                midiChannel: 0,
                number: UInt8((32 + index).clamped(to: 0...127))
            ))
            mappings.append(MIDIMapping(
                address: MixerParameterAddress(channelID: channelID, kind: .select),
                messageKind: .note,
                midiChannel: 0,
                number: UInt8((48 + index).clamped(to: 0...127))
            ))
        }
        return MIDIMapper(mappings: mappings)
    }

    public func encode(_ update: MixerParameterUpdate) throws -> MIDIMessage? {
        guard let mapping = mappings.first(where: { $0.address == update.address }) else {
            return nil
        }

        switch mapping.messageKind {
        case .controlChange:
            let value: Double
            switch update.value {
            case .double(let doubleValue):
                value = doubleValue
            case .bool(let boolValue):
                value = boolValue ? mapping.valueRange.maximum : mapping.valueRange.minimum
            }
            return try MIDIMessage(
                kind: .controlChange,
                channel: mapping.midiChannel,
                data1: mapping.number,
                data2: mapping.valueRange.midiValue(from: value)
            )
        case .note:
            guard let boolValue = update.value.boolValue else {
                throw MixerCoreError.invalidParameterValue("Note mappings expect Bool values.")
            }
            return try MIDIMessage(
                kind: boolValue ? .noteOn : .noteOff,
                channel: mapping.midiChannel,
                data1: mapping.number,
                data2: boolValue ? 127 : 0
            )
        }
    }

    public func decode(_ message: MIDIMessage) -> MixerParameterUpdate? {
        switch message.kind {
        case .controlChange:
            guard let channel = message.channel,
                  let controller = message.data1,
                  let value = message.data2,
                  let mapping = mappings.first(where: {
                      $0.messageKind == .controlChange &&
                      $0.midiChannel == channel &&
                      $0.number == controller
                  }) else {
                return nil
            }
            return MixerParameterUpdate(
                address: mapping.address,
                value: .double(mapping.valueRange.value(from: value))
            )
        case .noteOn, .noteOff:
            guard let channel = message.channel,
                  let note = message.data1,
                  let velocity = message.data2,
                  let mapping = mappings.first(where: {
                      $0.messageKind == .note &&
                      $0.midiChannel == channel &&
                      $0.number == note
                  }) else {
                return nil
            }
            return MixerParameterUpdate(
                address: mapping.address,
                value: .bool(message.kind == .noteOn && velocity > 0)
            )
        case .systemExclusive:
            return nil
        }
    }
}
