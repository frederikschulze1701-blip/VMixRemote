// SPDX-License-Identifier: Apache-2.0

import AppKit
import Foundation
import UniformTypeIdentifiers
import VMixCore
import VMixMIDI

enum MIDIBackendMode: String, CaseIterable, Identifiable {
    case mock
    case coreMIDI

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mock:
            return "Mock"
        case .coreMIDI:
            return "CoreMIDI"
        }
    }
}

struct AppErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
final class MixerViewModel: ObservableObject {
    @Published private(set) var profile: MixerProfile
    @Published var mixer: MixerModel
    @Published private(set) var devices: [MIDIDeviceInfo] = []
    @Published private(set) var activityLog: [MIDIActivity] = []
    @Published var selectedInputID: String?
    @Published var selectedOutputID: String?
    @Published var backendMode: MIDIBackendMode = .mock
    @Published var presentedError: AppErrorMessage?
    @Published var statusMessage = "Bereit"

    private let profileStore: ProfileStore
    private var midiBackend: any MIDIBackend

    var inputDevices: [MIDIDeviceInfo] {
        devices.filter(\.supportsInput)
    }

    var outputDevices: [MIDIDeviceInfo] {
        devices.filter(\.supportsOutput)
    }

    init() {
        let resolvedStore: ProfileStore
        do {
            resolvedStore = try ProfileStore()
        } catch {
            let temporaryRoot = FileManager.default.temporaryDirectory.appendingPathComponent("VMixRemote", isDirectory: true)
            resolvedStore = try! ProfileStore(rootDirectory: temporaryRoot)
        }

        let initialProfile = (try? resolvedStore.bootstrapDefaultProfileIfNeeded()) ?? MixerProfile.defaultMVP()
        self.profileStore = resolvedStore
        self.profile = initialProfile
        self.mixer = initialProfile.mixer
        self.midiBackend = MockMIDIBackend()
        configureBackend()
    }

    func switchBackend(to mode: MIDIBackendMode) {
        guard mode != backendMode else { return }
        midiBackend.disconnect()
        backendMode = mode

        do {
            switch mode {
            case .mock:
                midiBackend = MockMIDIBackend()
            case .coreMIDI:
                #if canImport(CoreMIDI)
                midiBackend = try CoreMIDIClientManager()
                #else
                throw MixerCoreError.invalidParameterValue("CoreMIDI is unavailable on this platform.")
                #endif
            }
            selectedInputID = nil
            selectedOutputID = nil
            configureBackend()
        } catch {
            present(error)
            backendMode = .mock
            midiBackend = MockMIDIBackend()
            configureBackend()
        }
    }

    func refreshDevices() {
        midiBackend.refreshDevices()
        devices = midiBackend.devices
        activityLog = midiBackend.activityLog
        statusMessage = "MIDI-Geräte aktualisiert"
    }

    func connectSelectedDevices() {
        do {
            try midiBackend.connect(inputID: selectedInputID, outputID: selectedOutputID)
            activityLog = midiBackend.activityLog
            statusMessage = "MIDI-Verbindung aktualisiert"
        } catch {
            present(error)
        }
    }

    func setFader(channelID: ChannelID, normalizedValue: Double) {
        applyLocalUpdate(MixerParameterUpdate(
            address: MixerParameterAddress(channelID: channelID, kind: .fader),
            value: .double(normalizedValue)
        ))
    }

    func setMute(channelID: ChannelID, isMuted: Bool) {
        applyLocalUpdate(MixerParameterUpdate(
            address: MixerParameterAddress(channelID: channelID, kind: .mute),
            value: .bool(isMuted)
        ))
    }

    func setSolo(channelID: ChannelID, isSolo: Bool) {
        applyLocalUpdate(MixerParameterUpdate(
            address: MixerParameterAddress(channelID: channelID, kind: .solo),
            value: .bool(isSolo)
        ))
    }

    func select(channelID: ChannelID) {
        applyLocalUpdate(MixerParameterUpdate(
            address: MixerParameterAddress(channelID: channelID, kind: .select),
            value: .bool(true)
        ))
    }

    func setPan(channelID: ChannelID, value: Double) {
        applyLocalUpdate(MixerParameterUpdate(
            address: MixerParameterAddress(channelID: channelID, kind: .pan),
            value: .double(value)
        ), sendMIDI: false)
    }

    func setEQ(channelID: ChannelID, bandIndex: Int, kind: ParameterKind, value: Double) {
        applyLocalUpdate(MixerParameterUpdate(
            address: MixerParameterAddress(channelID: channelID, kind: kind, eqBandIndex: bandIndex),
            value: .double(value)
        ), sendMIDI: false)
    }

    func saveProfile() {
        do {
            profile.mixer = mixer
            let url = try profileStore.save(profile)
            statusMessage = "Profil gespeichert: \(url.lastPathComponent)"
        } catch {
            present(error)
        }
    }

    func loadFirstAvailableProfile() {
        do {
            guard let url = try profileStore.listProfileURLs().sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).first else {
                profile = MixerProfile.defaultMVP()
                mixer = profile.mixer
                statusMessage = "Default-Profil geladen"
                return
            }
            try loadProfile(from: url)
        } catch {
            present(error)
        }
    }

    func chooseAndLoadProfile() {
        let panel = NSOpenPanel()
        panel.title = "Profil laden"
        panel.message = "Wähle ein gespeichertes VMixRemote-Profil."
        panel.prompt = "Laden"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = profileStore.profilesDirectory
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try loadProfile(from: url)
        } catch {
            present(error)
        }
    }

    func chooseAndImportProfile() {
        let panel = NSOpenPanel()
        panel.title = "Profil importieren"
        panel.message = "Importiert ein JSON-Profil und kopiert es nach Application Support."
        panel.prompt = "Importieren"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try importProfile(from: url)
        } catch {
            present(error)
        }
    }

    func chooseAndExportProfile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(profile.name).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try exportProfile(to: url)
        } catch {
            present(error)
        }
    }

    func loadProfile(from url: URL) throws {
        let loadedProfile = try profileStore.loadProfile(from: url)
        profile = loadedProfile
        mixer = loadedProfile.mixer
        statusMessage = "Profil geladen: \(url.lastPathComponent)"
    }

    func importProfile(from url: URL) throws {
        let importedProfile = try profileStore.importProfile(from: url)
        profile = importedProfile
        mixer = importedProfile.mixer
        statusMessage = "Profil importiert: \(url.lastPathComponent)"
    }

    func exportProfile(to url: URL) throws {
        profile.mixer = mixer
        let exportURL = try profileStore.exportProfile(profile, to: url)
        statusMessage = "Profil exportiert: \(exportURL.lastPathComponent)"
    }

    func migrateLegacyProfilesFromWorkspace() {
        do {
            let workspaceURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
            let migrated = try profileStore.migrateLegacyProfilePath(
                "VMix/BuildResources/Mixer Profiles\\",
                relativeTo: workspaceURL
            )
            if let first = migrated.first {
                let migratedProfile = try profileStore.loadProfile(from: first)
                profile = migratedProfile
                mixer = migratedProfile.mixer
                statusMessage = "Legacy-Profil migriert: \(first.lastPathComponent)"
            } else {
                statusMessage = "Keine Legacy-Profile gefunden"
            }
        } catch {
            present(error)
        }
    }

    func simulateMockFaderMove() {
        guard let mockBackend = midiBackend as? MockMIDIBackend else { return }
        let targetIndex = mixer.selectedChannelID?.index ?? 0
        let controller = UInt8(targetIndex.clamped(to: 0...127))
        let nextValue = UInt8.random(in: 0...127)
        do {
            let message = try MIDIMessage(kind: .controlChange, channel: 0, data1: controller, data2: nextValue)
            mockBackend.simulateIncoming(message)
            activityLog = midiBackend.activityLog
            statusMessage = "Mock-MIDI empfangen: CC \(controller)"
        } catch {
            present(error)
        }
    }

    private func configureBackend() {
        midiBackend.onReceive = { [weak self] message in
            Task { @MainActor in
                self?.handleIncoming(message)
            }
        }
        midiBackend.onDevicesChanged = { [weak self] devices in
            Task { @MainActor in
                self?.devices = devices
                self?.activityLog = self?.midiBackend.activityLog ?? []
            }
        }
        midiBackend.refreshDevices()
        devices = midiBackend.devices
        activityLog = midiBackend.activityLog
    }

    private func handleIncoming(_ message: MIDIMessage) {
        guard let update = profile.midiMapper.decode(message) else {
            activityLog = midiBackend.activityLog
            return
        }
        do {
            try mixer.update(update)
            profile.mixer = mixer
            activityLog = midiBackend.activityLog
        } catch {
            present(error)
        }
    }

    private func applyLocalUpdate(_ update: MixerParameterUpdate, sendMIDI: Bool = true) {
        do {
            try mixer.update(update)
            profile.mixer = mixer
            if sendMIDI, let message = try profile.midiMapper.encode(update) {
                try midiBackend.send(message)
                activityLog = midiBackend.activityLog
            }
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        statusMessage = "Fehler"
        presentedError = AppErrorMessage(message: error.localizedDescription)
    }
}
