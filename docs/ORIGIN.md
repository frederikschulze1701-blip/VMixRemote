<!-- SPDX-License-Identifier: Apache-2.0 -->

# Origin and Licensing

VMixRemote is a new native macOS implementation inspired by
[`space928/VMix`](https://github.com/space928/VMix).

The original project describes VMix as virtual mixer control software for
MIDI-enabled digital mixers, with concepts such as:

- flexible mixer remote control for digital mixers
- WPF/.NET user interface
- extensible MIDI translation
- scene storage and playback
- fader panel
- selected-channel processing editor
- Yamaha 02R support
- dark theme
- eight virtual DCA fader groups

This repository rebuilds the idea in Swift and SwiftUI for macOS. It does not
copy WPF, XAML, `System.Windows`, or C# implementation files from the original
project.

## Licensing

- The Swift/macOS implementation in this repository is licensed under Apache
  License 2.0.
- The historical `space928/VMix` project retains its own NPOSL-3.0 licensing.
- Any future direct port of original code or assets should be reviewed against
  the original license before redistribution.
