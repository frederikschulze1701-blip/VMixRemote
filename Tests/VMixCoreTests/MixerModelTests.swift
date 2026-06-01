// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import VMixCore

final class MixerModelTests: XCTestCase {
    func testFaderClamping() {
        var fader = FaderValue(normalized: 2.0)
        XCTAssertEqual(fader.normalized, 1.0)

        fader.setNormalized(-1.0)
        XCTAssertEqual(fader.normalized, 0.0)
    }

    func testEQClamping() {
        let band = EQBand(id: 0, frequency: 50_000, gainDecibels: -40, q: 20)
        XCTAssertEqual(band.frequency, 20_000)
        XCTAssertEqual(band.gainDecibels, -18)
        XCTAssertEqual(band.q, 10)
    }

    func testMixerStateUpdates() throws {
        var mixer = MixerModel(channelCount: 8)
        let channelID = ChannelID(index: 1)

        try mixer.update(MixerParameterUpdate(
            address: MixerParameterAddress(channelID: channelID, kind: .fader),
            value: .double(0.25)
        ))
        try mixer.update(MixerParameterUpdate(
            address: MixerParameterAddress(channelID: channelID, kind: .mute),
            value: .bool(true)
        ))

        let channel = try mixer.channel(for: channelID)
        XCTAssertEqual(channel.fader.normalized, 0.25)
        XCTAssertTrue(channel.isMuted)
    }

    func testSelectIsExclusive() throws {
        var mixer = MixerModel(channelCount: 8)
        try mixer.update(MixerParameterUpdate(
            address: MixerParameterAddress(channelID: ChannelID(index: 3), kind: .select),
            value: .bool(true)
        ))

        XCTAssertEqual(mixer.selectedChannelID, ChannelID(index: 3))
        XCTAssertEqual(mixer.channels.filter(\.isSelected).count, 1)
    }
}
