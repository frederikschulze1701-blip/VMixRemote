<!-- SPDX-License-Identifier: Apache-2.0 -->

# VMixRemote

VMixRemote is a native macOS rebuild of the original VMix mixer-remote idea. It
is written in Swift and SwiftUI, keeps mixer logic in a platform-neutral core,
and talks to MIDI through a testable backend abstraction.

Project page: https://frederikschulze1701-blip.github.io/VMixRemote/

Origin: VMixRemote is inspired by
[`space928/VMix`](https://github.com/space928/VMix), a WPF/.NET virtual mixer
control project for MIDI-enabled digital mixers. The Swift/macOS rewrite in this
repository does not copy WPF, XAML, `System.Windows`, or C# implementation files.

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

```bash
brew tap frederikschulze1701-blip/vmixremote
brew install vmix-remote
```

Or in one command:

```bash
brew install frederikschulze1701-blip/vmixremote/vmix-remote
```

## License

The Swift/macOS rewrite in this repository is licensed under Apache License 2.0.
The historical WPF/C# reference project is not relicensed by this rewrite.
