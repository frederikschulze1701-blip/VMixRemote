// SPDX-License-Identifier: Apache-2.0

import Foundation

public enum MIDIMessageKind: String, Codable, Equatable, Sendable {
    case controlChange
    case noteOn
    case noteOff
    case systemExclusive
}

public struct MIDIMessage: Codable, Equatable, Sendable {
    public var kind: MIDIMessageKind
    public var channel: UInt8?
    public var data1: UInt8?
    public var data2: UInt8?
    public var payload: [UInt8]

    public init(
        kind: MIDIMessageKind,
        channel: UInt8? = nil,
        data1: UInt8? = nil,
        data2: UInt8? = nil,
        payload: [UInt8] = []
    ) throws {
        switch kind {
        case .controlChange, .noteOn, .noteOff:
            guard let channel, channel <= 15 else {
                throw MixerCoreError.invalidParameterValue("MIDI channel must be 0...15.")
            }
            guard let data1, data1 <= 127, let data2, data2 <= 127 else {
                throw MixerCoreError.invalidParameterValue("MIDI data bytes must be 0...127.")
            }
            self.channel = channel
            self.data1 = data1
            self.data2 = data2
            self.payload = []
        case .systemExclusive:
            guard payload.first == 0xF0, payload.last == 0xF7 else {
                throw MixerCoreError.invalidParameterValue("SysEx messages must start with F0 and end with F7.")
            }
            self.channel = nil
            self.data1 = nil
            self.data2 = nil
            self.payload = payload
        }
        self.kind = kind
    }

    public init(bytes: [UInt8]) throws {
        guard let status = bytes.first else {
            throw MixerCoreError.unsupportedMIDIMessage(bytes)
        }

        if status == 0xF0 {
            try self.init(kind: .systemExclusive, payload: bytes)
            return
        }

        guard bytes.count >= 3 else {
            throw MixerCoreError.unsupportedMIDIMessage(bytes)
        }

        let messageType = status & 0xF0
        let channel = status & 0x0F
        switch messageType {
        case 0xB0:
            try self.init(kind: .controlChange, channel: channel, data1: bytes[1], data2: bytes[2])
        case 0x90:
            if bytes[2] == 0 {
                try self.init(kind: .noteOff, channel: channel, data1: bytes[1], data2: bytes[2])
            } else {
                try self.init(kind: .noteOn, channel: channel, data1: bytes[1], data2: bytes[2])
            }
        case 0x80:
            try self.init(kind: .noteOff, channel: channel, data1: bytes[1], data2: bytes[2])
        default:
            throw MixerCoreError.unsupportedMIDIMessage(bytes)
        }
    }

    public var bytes: [UInt8] {
        switch kind {
        case .controlChange:
            return [0xB0 | (channel ?? 0), data1 ?? 0, data2 ?? 0]
        case .noteOn:
            return [0x90 | (channel ?? 0), data1 ?? 0, data2 ?? 0]
        case .noteOff:
            return [0x80 | (channel ?? 0), data1 ?? 0, data2 ?? 0]
        case .systemExclusive:
            return payload
        }
    }
}
