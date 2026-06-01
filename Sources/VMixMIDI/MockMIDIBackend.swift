// SPDX-License-Identifier: Apache-2.0

import Foundation
import VMixCore

public final class MockMIDIBackend: MIDIBackend {
    public private(set) var devices: [MIDIDeviceInfo]
    public private(set) var activityLog: [MIDIActivity] = []

    public var onReceive: ((MIDIMessage) -> Void)?
    public var onDevicesChanged: (([MIDIDeviceInfo]) -> Void)?

    public private(set) var connectedInputID: String?
    public private(set) var connectedOutputID: String?
    public private(set) var sentMessages: [MIDIMessage] = []

    public init(devices: [MIDIDeviceInfo] = MockMIDIBackend.defaultDevices) {
        self.devices = devices
    }

    public static var defaultDevices: [MIDIDeviceInfo] {
        [
            MIDIDeviceInfo(
                id: "mock-input-output",
                name: "VMix Mock Device",
                manufacturer: "VMixRemote",
                supportsInput: true,
                supportsOutput: true
            ),
            MIDIDeviceInfo(
                id: "mock-playback",
                name: "Mock Playback",
                manufacturer: "VMixRemote",
                supportsInput: false,
                supportsOutput: true
            )
        ]
    }

    public func refreshDevices() {
        appendSystemActivity("Mock devices refreshed")
        onDevicesChanged?(devices)
    }

    public func connect(inputID: String?, outputID: String?) throws {
        if let inputID, !devices.contains(where: { $0.id == inputID && $0.supportsInput }) {
            throw MixerCoreError.missingMIDIDevice(inputID)
        }
        if let outputID, !devices.contains(where: { $0.id == outputID && $0.supportsOutput }) {
            throw MixerCoreError.missingMIDIDevice(outputID)
        }
        connectedInputID = inputID
        connectedOutputID = outputID
        appendSystemActivity("Mock MIDI connected")
    }

    public func disconnect() {
        connectedInputID = nil
        connectedOutputID = nil
        appendSystemActivity("Mock MIDI disconnected")
    }

    public func send(_ message: MIDIMessage) throws {
        sentMessages.append(message)
        activityLog.append(MIDIActivity(direction: .outgoing, bytes: message.bytes, deviceName: connectedOutputID))
    }

    public func simulateIncoming(_ message: MIDIMessage) {
        activityLog.append(MIDIActivity(direction: .incoming, bytes: message.bytes, deviceName: connectedInputID))
        onReceive?(message)
    }

    private func appendSystemActivity(_ message: String) {
        activityLog.append(MIDIActivity(direction: .system, bytes: Array(message.utf8), deviceName: nil))
    }
}
