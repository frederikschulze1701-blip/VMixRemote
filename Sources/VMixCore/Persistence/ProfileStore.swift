// SPDX-License-Identifier: Apache-2.0

import Foundation

public final class ProfileStore {
    public let rootDirectory: URL
    public let profilesDirectory: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(rootDirectory: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else {
            self.rootDirectory = try Self.defaultRootDirectory(fileManager: fileManager)
        }
        self.profilesDirectory = self.rootDirectory.appendingPathComponent("Profiles", isDirectory: true)

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public static func defaultRootDirectory(fileManager: FileManager = .default) throws -> URL {
        guard let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw MixerCoreError.corruptProfile("Application Support directory is unavailable.")
        }
        return applicationSupport.appendingPathComponent("VMixRemote", isDirectory: true)
    }

    public func ensureDirectories() throws {
        try fileManager.createDirectory(at: profilesDirectory, withIntermediateDirectories: true)
    }

    @discardableResult
    public func bootstrapDefaultProfileIfNeeded() throws -> MixerProfile {
        try ensureDirectories()
        let existingProfiles = try listProfileURLs()
        if let firstProfile = existingProfiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).first {
            return try loadProfile(from: firstProfile)
        }
        let profile = MixerProfile.defaultMVP()
        try save(profile)
        return profile
    }

    public func listProfileURLs() throws -> [URL] {
        try ensureDirectories()
        return try fileManager.contentsOfDirectory(
            at: profilesDirectory,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension.lowercased() == "json" }
    }

    @discardableResult
    public func save(_ profile: MixerProfile, fileName: String? = nil) throws -> URL {
        try ensureDirectories()
        var profile = profile
        profile.modifiedAt = Date()
        let targetURL = profilesDirectory.appendingPathComponent(fileName ?? sanitizedFileName(for: profile))
        let data = try encoder.encode(profile)
        try data.write(to: targetURL, options: .atomic)
        return targetURL
    }

    public func loadProfile(named name: String) throws -> MixerProfile {
        let fileName = name.hasSuffix(".json") ? name : "\(name).json"
        return try loadProfile(from: profilesDirectory.appendingPathComponent(fileName))
    }

    public func loadProfile(from url: URL) throws -> MixerProfile {
        let data = try Data(contentsOf: url)
        if let profile = try? decoder.decode(MixerProfile.self, from: data) {
            return profile
        }
        if let legacy = try? decoder.decode(LegacyMixerProfile.self, from: data) {
            let name = url.deletingPathExtension().lastPathComponent
            return legacy.migratedProfile(name: name)
        }
        throw MixerCoreError.corruptProfile(url.lastPathComponent)
    }

    @discardableResult
    public func importProfile(from url: URL) throws -> MixerProfile {
        let profile = try loadProfile(from: url)
        try save(profile, fileName: url.lastPathComponent)
        return profile
    }

    @discardableResult
    public func exportProfile(_ profile: MixerProfile, to url: URL) throws -> URL {
        var exportURL = url
        if exportURL.pathExtension.isEmpty {
            exportURL.appendPathExtension("json")
        }
        let data = try encoder.encode(profile)
        try data.write(to: exportURL, options: .atomic)
        return exportURL
    }

    @discardableResult
    public func migrateLegacyProfiles(from legacyDirectory: URL) throws -> [URL] {
        try ensureDirectories()
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: legacyDirectory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return []
        }

        let legacyFiles = try fileManager.contentsOfDirectory(
            at: legacyDirectory,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension.lowercased() == "json" }

        var migratedURLs: [URL] = []
        for legacyFile in legacyFiles {
            do {
                let profile = try loadProfile(from: legacyFile)
                let savedURL = try save(profile, fileName: legacyFile.lastPathComponent)
                migratedURLs.append(savedURL)
            } catch {
                throw MixerCoreError.profileMigrationFailed("\(legacyFile.lastPathComponent): \(error.localizedDescription)")
            }
        }
        return migratedURLs
    }

    @discardableResult
    public func migrateLegacyProfilePath(_ legacyPath: String, relativeTo baseDirectory: URL) throws -> [URL] {
        let normalizedPath = legacyPath.replacingOccurrences(of: "\\", with: "/")
        let legacyURL: URL
        if normalizedPath.hasPrefix("/") {
            legacyURL = URL(fileURLWithPath: normalizedPath, isDirectory: true)
        } else {
            legacyURL = baseDirectory.appendingPathComponent(normalizedPath, isDirectory: true)
        }
        return try migrateLegacyProfiles(from: legacyURL)
    }

    private func sanitizedFileName(for profile: MixerProfile) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let cleaned = profile.name
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(cleaned.isEmpty ? "Mixer Profile" : cleaned).json"
    }
}
