// SPDX-License-Identifier: Apache-2.0

import Foundation
import VMixCore

#if canImport(CoreMIDI)
import CoreMIDI

public final class CoreMIDIClientManager: MIDIBackend {
    public private(set) var devices: [MIDIDeviceInfo] = []
    public private(set) var activityLog: [MIDIActivity] = []

    public var onReceive: ((MIDIMessage) -> Void)?
    public var onDevicesChanged: (([MIDIDeviceInfo]) -> Void)?

    private var client = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private var outputPort = MIDIPortRef()
    private var connectedInputEndpoint = MIDIEndpointRef()
    private var connectedOutputEndpoint = MIDIEndpointRef()
    private var inputEndpoints: [String: MIDIEndpointRef] = [:]
    private var outputEndpoints: [String: MIDIEndpointRef] = [:]

    public init(clientName: String = "VMixRemote") throws {
        let clientStatus = MIDIClientCreateWithBlock(clientName as CFString, &client) { [weak self] _ in
            self?.refreshDevices()
        }
        guard clientStatus == noErr else {
            throw MixerCoreError.invalidParameterValue("CoreMIDI client creation failed: \(clientStatus).")
        }

        let inputStatus = MIDIInputPortCreateWithBlock(client, "VMixRemote Input" as CFString, &inputPort) { [weak self] packetList, _ in
            self?.handleIncomingPacketList(packetList)
        }
        guard inputStatus == noErr else {
            throw MixerCoreError.invalidParameterValue("CoreMIDI input port creation failed: \(inputStatus).")
        }

        let outputStatus = MIDIOutputPortCreate(client, "VMixRemote Output" as CFString, &outputPort)
        guard outputStatus == noErr else {
            throw MixerCoreError.invalidParameterValue("CoreMIDI output port creation failed: \(outputStatus).")
        }

        refreshDevices()
    }

    deinit {
        disconnect()
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }
        if outputPort != 0 {
            MIDIPortDispose(outputPort)
        }
        if client != 0 {
            MIDIClientDispose(client)
        }
    }

    public func refreshDevices() {
        var nextDevices: [MIDIDeviceInfo] = []
        inputEndpoints.removeAll()
        outputEndpoints.removeAll()

        for index in 0..<MIDIGetNumberOfSources() {
            let endpoint = MIDIGetSource(index)
            guard endpoint != 0 else { continue }
            let id = "in-\(Self.uniqueID(for: endpoint))"
            inputEndpoints[id] = endpoint
            nextDevices.append(MIDIDeviceInfo(
                id: id,
                name: Self.displayName(for: endpoint),
                manufacturer: Self.stringProperty(kMIDIPropertyManufacturer, endpoint: endpoint),
                supportsInput: true,
                supportsOutput: false
            ))
        }

        for index in 0..<MIDIGetNumberOfDestinations() {
            let endpoint = MIDIGetDestination(index)
            guard endpoint != 0 else { continue }
            let id = "out-\(Self.uniqueID(for: endpoint))"
            outputEndpoints[id] = endpoint
            nextDevices.append(MIDIDeviceInfo(
                id: id,
                name: Self.displayName(for: endpoint),
                manufacturer: Self.stringProperty(kMIDIPropertyManufacturer, endpoint: endpoint),
                supportsInput: false,
                supportsOutput: true
            ))
        }

        devices = nextDevices.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        activityLog.append(MIDIActivity(direction: .system, bytes: Array("CoreMIDI devices refreshed".utf8)))
        onDevicesChanged?(devices)
    }

    public func connect(inputID: String?, outputID: String?) throws {
        if connectedInputEndpoint != 0 {
            MIDIPortDisconnectSource(inputPort, connectedInputEndpoint)
            connectedInputEndpoint = 0
        }

        if let inputID {
            guard let endpoint = inputEndpoints[inputID] else {
                throw MixerCoreError.missingMIDIDevice(inputID)
            }
            let status = MIDIPortConnectSource(inputPort, endpoint, nil)
            guard status == noErr else {
                throw MixerCoreError.invalidParameterValue("CoreMIDI input connection failed: \(status).")
            }
            connectedInputEndpoint = endpoint
        }

        if let outputID {
            guard let endpoint = outputEndpoints[outputID] else {
                throw MixerCoreError.missingMIDIDevice(outputID)
            }
            connectedOutputEndpoint = endpoint
        } else {
            connectedOutputEndpoint = 0
        }

        activityLog.append(MIDIActivity(direction: .system, bytes: Array("CoreMIDI connected".utf8)))
    }

    public func disconnect() {
        if connectedInputEndpoint != 0 {
            MIDIPortDisconnectSource(inputPort, connectedInputEndpoint)
            connectedInputEndpoint = 0
        }
        connectedOutputEndpoint = 0
    }

    public func send(_ message: MIDIMessage) throws {
        guard connectedOutputEndpoint != 0 else {
            throw MixerCoreError.missingMIDIDevice("No CoreMIDI output is connected.")
        }

        let bytes = message.bytes
        let packetListSize = max(1024, bytes.count + MemoryLayout<MIDIPacketList>.size + 64)
        let rawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: packetListSize,
            alignment: MemoryLayout<MIDIPacketList>.alignment
        )
        defer { rawPointer.deallocate() }

        let packetListPointer = rawPointer.bindMemory(to: MIDIPacketList.self, capacity: 1)
        var packet = MIDIPacketListInit(packetListPointer)
        let addedPacket = bytes.withUnsafeBufferPointer { buffer -> UnsafeMutablePointer<MIDIPacket>? in
            guard let baseAddress = buffer.baseAddress else { return nil }
            return MIDIPacketListAdd(packetListPointer, packetListSize, packet, 0, buffer.count, baseAddress)
        }
        guard addedPacket != nil else {
            throw MixerCoreError.unsupportedMIDIMessage(bytes)
        }
        packet = addedPacket!

        let status = MIDISend(outputPort, connectedOutputEndpoint, packetListPointer)
        guard status == noErr else {
            throw MixerCoreError.invalidParameterValue("CoreMIDI send failed: \(status).")
        }
        activityLog.append(MIDIActivity(direction: .outgoing, bytes: bytes))
    }

    private func handleIncomingPacketList(_ packetList: UnsafePointer<MIDIPacketList>) {
        var packet = packetList.pointee.packet
        for _ in 0..<packetList.pointee.numPackets {
            var packetData = packet.data
            let bytes = withUnsafeBytes(of: &packetData) { rawBuffer in
                Array(rawBuffer.prefix(Int(packet.length)))
            }
            if let message = try? MIDIMessage(bytes: bytes) {
                activityLog.append(MIDIActivity(direction: .incoming, bytes: bytes))
                onReceive?(message)
            } else {
                activityLog.append(MIDIActivity(direction: .system, bytes: bytes))
            }
            packet = MIDIPacketNext(&packet).pointee
        }
    }

    private static func displayName(for endpoint: MIDIObjectRef) -> String {
        stringProperty(kMIDIPropertyDisplayName, endpoint: endpoint)
            ?? stringProperty(kMIDIPropertyName, endpoint: endpoint)
            ?? "MIDI Endpoint \(endpoint)"
    }

    private static func stringProperty(_ property: CFString, endpoint: MIDIObjectRef) -> String? {
        var unmanagedString: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, property, &unmanagedString)
        guard status == noErr else { return nil }
        return unmanagedString?.takeRetainedValue() as String?
    }

    private static func uniqueID(for endpoint: MIDIObjectRef) -> Int32 {
        var uniqueID: Int32 = 0
        let status = MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uniqueID)
        if status == noErr {
            return uniqueID
        }
        return Int32(endpoint)
    }
}
#endif
