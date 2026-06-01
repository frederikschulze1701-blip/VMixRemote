// SPDX-License-Identifier: Apache-2.0

import Foundation

public enum MixerCoreError: Error, Equatable, LocalizedError {
    case invalidChannelIndex(Int)
    case invalidParameterValue(String)
    case missingMIDIDevice(String)
    case unsupportedMIDIMessage([UInt8])
    case corruptProfile(String)
    case profileMigrationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidChannelIndex(let index):
            return "Invalid channel index: \(index)."
        case .invalidParameterValue(let detail):
            return "Invalid parameter value: \(detail)."
        case .missingMIDIDevice(let device):
            return "Missing MIDI device: \(device)."
        case .unsupportedMIDIMessage(let bytes):
            return "Unsupported MIDI message: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))."
        case .corruptProfile(let detail):
            return "Corrupt mixer profile: \(detail)."
        case .profileMigrationFailed(let detail):
            return "Profile migration failed: \(detail)."
        }
    }
}

public extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, limits.lowerBound), limits.upperBound)
    }
}
