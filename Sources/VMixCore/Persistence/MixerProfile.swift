// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct MixerScene: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var mixer: MixerModel

    public init(id: UUID = UUID(), name: String, mixer: MixerModel) {
        self.id = id
        self.name = name
        self.mixer = mixer
    }
}

public struct MixerProfile: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var version: Int
    public var name: String
    public var mixer: MixerModel
    public var scenes: [MixerScene]
    public var midiMapper: MIDIMapper
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        version: Int = 1,
        name: String,
        mixer: MixerModel,
        scenes: [MixerScene] = [],
        midiMapper: MIDIMapper,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.version = version
        self.name = name
        self.mixer = mixer
        self.scenes = scenes
        self.midiMapper = midiMapper
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    public static func defaultMVP(channelCount: Int = 8) -> MixerProfile {
        let mixer = MixerModel(channelCount: channelCount)
        return MixerProfile(
            name: "Default VMix Remote",
            mixer: mixer,
            scenes: [
                MixerScene(name: "Scene 1", mixer: mixer)
            ],
            midiMapper: MIDIMapper.defaultChannelStripMapper(channelCount: channelCount)
        )
    }
}

public struct LegacyMixerProfile: Decodable, Equatable, Sendable {
    public var mixChannels: Int
    public var auxChannels: Int
    public var busChannels: Int
    public var specialChannels: [String]
    public var midiManager: String
    public var channelStripHardware: [String]

    enum CodingKeys: String, CodingKey {
        case mixChannels = "MixChannels"
        case auxChannels = "AuxChannels"
        case busChannels = "BusChannels"
        case specialChannels = "SpecialChannels"
        case midiManager = "MidiManager"
        case channelStripHardware = "ChannelStripHardware"
    }

    public func migratedProfile(name: String = "Migrated VMix Profile") -> MixerProfile {
        let channelCount = max(1, mixChannels)
        var profile = MixerProfile.defaultMVP(channelCount: channelCount)
        profile.name = name
        profile.scenes = [MixerScene(name: "Migrated Scene", mixer: profile.mixer)]
        return profile
    }
}
