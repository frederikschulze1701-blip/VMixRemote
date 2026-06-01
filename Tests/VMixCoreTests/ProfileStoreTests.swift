// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import VMixCore

final class ProfileStoreTests: XCTestCase {
    func testProfileSerializationRoundTrip() throws {
        let root = temporaryDirectory()
        let store = try ProfileStore(rootDirectory: root)
        let profile = MixerProfile.defaultMVP(channelCount: 8)

        let url = try store.save(profile)
        let loaded = try store.loadProfile(from: url)

        XCTAssertEqual(loaded.mixer.channels.count, 8)
        XCTAssertEqual(loaded.midiMapper.mappings.count, 32)
    }

    func testLegacyProfileMigrationFromWindowsStylePath() throws {
        let root = temporaryDirectory()
        let store = try ProfileStore(rootDirectory: root.appendingPathComponent("Application Support", isDirectory: true))
        let legacyRoot = root.appendingPathComponent("Mixer Profiles", isDirectory: true)
        try FileManager.default.createDirectory(at: legacyRoot, withIntermediateDirectories: true)

        let legacyJSON = """
        {
          "MixChannels": 8,
          "AuxChannels": 2,
          "BusChannels": 2,
          "SpecialChannels": [],
          "MidiManager": "02r",
          "ChannelStripHardware": ["ParametricEQ"]
        }
        """
        try legacyJSON.data(using: .utf8)?.write(to: legacyRoot.appendingPathComponent("02r.json"))

        let migrated = try store.migrateLegacyProfilePath("Mixer Profiles\\", relativeTo: root)

        XCTAssertEqual(migrated.count, 1)
        let profile = try store.loadProfile(from: migrated[0])
        XCTAssertEqual(profile.name, "02r")
        XCTAssertEqual(profile.mixer.channels.count, 8)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("VMixRemoteTests-\(UUID().uuidString)", isDirectory: true)
    }
}
