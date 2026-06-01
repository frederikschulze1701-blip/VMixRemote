<!-- SPDX-License-Identifier: Apache-2.0 -->

# VMixRemote

VMixRemote is a native macOS rebuild of the original VMix mixer-remote idea. It
is written in Swift and SwiftUI, keeps mixer logic in a platform-neutral core,
and talks to MIDI through a testable backend abstraction.

## Status

This is an MVP:

- 8 input channel strips
- fader, meter, mute, solo, select
- reusable SwiftUI mixer controls
- JSON/Codable profile storage in Application Support
- Mock MIDI backend for hardware-free testing
- CoreMIDI backend scaffold for real devices
- XCTest coverage for core state, MIDI codecs, profile storage, migration, and mock MIDI

## Build

```bash
swift test
./script/build_and_run.sh
```

The run script stages a local app bundle at `dist/VMix Remote.app`.

## Homebrew

After the `v0.1.0` tag exists on GitHub:

```bash
brew install --HEAD https://raw.githubusercontent.com/frederikschulze1701-blip/VMixRemote/main/Formula/vmix-remote.rb
```

For local formula testing:

```bash
brew install --build-from-source ./Formula/vmix-remote.rb
```

## License

The Swift/macOS rewrite in this repository is licensed under Apache License 2.0.
The historical WPF/C# reference project is not relicensed by this rewrite.
