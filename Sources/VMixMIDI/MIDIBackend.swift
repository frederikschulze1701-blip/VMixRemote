// SPDX-License-Identifier: Apache-2.0

import Foundation
import VMixCore

public struct MIDIDeviceInfo: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var manufacturer: String?
    public var supportsInput: Bool
    public var supportsOutput: Bool

    public init(
        id: String,
        name: String,
        manufacturer: String? = nil,
        supportsInput: Bool,
        supportsOutput: Bool
    ) {
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
        self.supportsInput = supportsInput
        self.supportsOutput = supportsOutput
    }
}

public enum MIDIActivityDirection: String, Codable, Equatable, Sendable {
    case incoming
    case outgoing
    case system
}

public struct MIDIActivity: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var direction: MIDIActivityDirection
    public var bytes: [UInt8]
    public var deviceName: String?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        direction: MIDIActivityDirection,
        bytes: [UInt8],
        deviceName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.direction = direction
        self.bytes = bytes
        self.deviceName = deviceName
    }
}

public protocol MIDIBackend: AnyObject {
    var devices: [MIDIDeviceInfo] { get }
    var activityLog: [MIDIActivity] { get }
    var onReceive: ((MIDIMessage) -> Void)? { get set }
    var onDevicesChanged: (([MIDIDeviceInfo]) -> Void)? { get set }

    func refreshDevices()
    func connect(inputID: String?, outputID: String?) throws
    func disconnect()
    func send(_ message: MIDIMessage) throws
}
