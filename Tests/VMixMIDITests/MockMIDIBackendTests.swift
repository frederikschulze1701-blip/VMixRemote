// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import VMixCore
@testable import VMixMIDI

final class MockMIDIBackendTests: XCTestCase {
    func testMockSendRecordsOutgoingMessage() throws {
        let backend = MockMIDIBackend()
        try backend.connect(inputID: "mock-input-output", outputID: "mock-input-output")

        let message = try MIDIMessage(kind: .controlChange, channel: 0, data1: 1, data2: 64)
        try backend.send(message)

        XCTAssertEqual(backend.sentMessages, [message])
        XCTAssertEqual(backend.activityLog.last?.direction, .outgoing)
    }

    func testMockIncomingCallsReceiveHandler() throws {
        let backend = MockMIDIBackend()
        let expectation = expectation(description: "Incoming MIDI")
        let message = try MIDIMessage(kind: .noteOn, channel: 0, data1: 16, data2: 127)

        backend.onReceive = { receivedMessage in
            XCTAssertEqual(receivedMessage, message)
            expectation.fulfill()
        }

        backend.simulateIncoming(message)
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(backend.activityLog.last?.direction, .incoming)
    }
}
