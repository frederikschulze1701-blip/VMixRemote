// swift-tools-version: 5.9
// SPDX-License-Identifier: Apache-2.0

import PackageDescription

let package = Package(
    name: "VMixRemote",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "VMixCore", targets: ["VMixCore"]),
        .library(name: "VMixMIDI", targets: ["VMixMIDI"]),
        .executable(name: "VMixRemoteApp", targets: ["VMixRemoteApp"])
    ],
    targets: [
        .target(
            name: "VMixCore",
            path: "Sources/VMixCore"
        ),
        .target(
            name: "VMixMIDI",
            dependencies: ["VMixCore"],
            path: "Sources/VMixMIDI"
        ),
        .executableTarget(
            name: "VMixRemoteApp",
            dependencies: ["VMixCore", "VMixMIDI"],
            path: "Sources/VMixRemoteApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "VMixCoreTests",
            dependencies: ["VMixCore"],
            path: "Tests/VMixCoreTests"
        ),
        .testTarget(
            name: "VMixMIDITests",
            dependencies: ["VMixCore", "VMixMIDI"],
            path: "Tests/VMixMIDITests"
        )
    ]
)
