// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import VMixCore

final class MIDIMessageTests: XCTestCase {
    func testControlChangeEncoding() throws {
        let message = try MIDIMessage(kind: .controlChange, channel: 2, data1: 7, data2: 100)
        XCTAssertEqual(message.bytes, [0xB2, 0x07, 0x64])
    }

    func testControlChangeDecoding() throws {
        let message = try MIDIMessage(bytes: [0xB0, 0x10, 0x7F])
        XCTAssertEqual(message.kind, .controlChange)
        XCTAssertEqual(message.channel, 0)
        XCTAssertEqual(message.data1, 16)
        XCTAssertEqual(message.data2, 127)
    }

    func testNoteOnVelocityZeroDecodesAsNoteOff() throws {
        let message = try MIDIMessage(bytes: [0x90, 0x20, 0x00])
        XCTAssertEqual(message.kind, .noteOff)
    }

    func testSysExDecoding() throws {
        let message = try MIDIMessage(bytes: [0xF0, 0x43, 0x10, 0x3D, 0xF7])
        XCTAssertEqual(message.kind, .systemExclusive)
        XCTAssertEqual(message.bytes, [0xF0, 0x43, 0x10, 0x3D, 0xF7])
    }

    func testUnsupportedMessageThrows() {
        XCTAssertThrowsError(try MIDIMessage(bytes: [0xC0, 0x01]))
    }
}
