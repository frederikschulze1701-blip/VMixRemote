// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import VMixCore

final class MIDIMapperTests: XCTestCase {
    func testDefaultFaderMappingEncodesControlChange() throws {
        let mapper = MIDIMapper.defaultChannelStripMapper(channelCount: 8)
        let update = MixerParameterUpdate(
            address: MixerParameterAddress(channelID: ChannelID(index: 3), kind: .fader),
            value: .double(0.5)
        )

        let message = try mapper.encode(update)
        XCTAssertEqual(message?.kind, .controlChange)
        XCTAssertEqual(message?.bytes, [0xB0, 0x03, 0x40])
    }

    func testDefaultMuteMappingEncodesNoteOnOff() throws {
        let mapper = MIDIMapper.defaultChannelStripMapper(channelCount: 8)
        let address = MixerParameterAddress(channelID: ChannelID(index: 2), kind: .mute)

        let noteOn = try mapper.encode(MixerParameterUpdate(address: address, value: .bool(true)))
        let noteOff = try mapper.encode(MixerParameterUpdate(address: address, value: .bool(false)))

        XCTAssertEqual(noteOn?.bytes, [0x90, 0x12, 0x7F])
        XCTAssertEqual(noteOff?.bytes, [0x80, 0x12, 0x00])
    }

    func testDecodeControlChangeToFaderUpdate() throws {
        let mapper = MIDIMapper.defaultChannelStripMapper(channelCount: 8)
        let message = try MIDIMessage(bytes: [0xB0, 0x04, 0x7F])

        let update = mapper.decode(message)

        XCTAssertEqual(update?.address, MixerParameterAddress(channelID: ChannelID(index: 4), kind: .fader))
        XCTAssertEqual(update?.value, .double(1.0))
    }
}
