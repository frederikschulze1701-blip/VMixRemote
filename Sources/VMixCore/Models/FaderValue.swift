// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct FaderValue: Codable, Equatable, Sendable {
    public static let minimumDecibels = -99.0
    public static let maximumDecibels = 10.0

    public private(set) var normalized: Double

    public init(normalized: Double = 0.75) {
        self.normalized = normalized.clamped(to: 0.0...1.0)
    }

    public init(decibels: Double) {
        self.normalized = Self.normalized(fromDecibels: decibels)
    }

    public var decibels: Double {
        Self.decibels(fromNormalized: normalized)
    }

    public mutating func setNormalized(_ value: Double) {
        normalized = value.clamped(to: 0.0...1.0)
    }

    public mutating func setDecibels(_ value: Double) {
        normalized = Self.normalized(fromDecibels: value)
    }

    public static func decibels(fromNormalized value: Double) -> Double {
        let clamped = value.clamped(to: 0.0...1.0)
        return minimumDecibels + (maximumDecibels - minimumDecibels) * clamped
    }

    public static func normalized(fromDecibels value: Double) -> Double {
        let clamped = value.clamped(to: minimumDecibels...maximumDecibels)
        return (clamped - minimumDecibels) / (maximumDecibels - minimumDecibels)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(normalized: try container.decode(Double.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(normalized)
    }
}
