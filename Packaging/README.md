<!-- SPDX-License-Identifier: Apache-2.0 -->

# VMixRemote Packaging

Current bundle identifier: `com.vmixremote.macos`

The SwiftPM run script stages `dist/VMix Remote.app` with a minimal `Info.plist`
and the project icon at `Sources/VMixRemoteApp/Resources/AppIcon.icns`.
Before distribution:

- Add release signing with Developer ID Application.
- Enable hardened runtime when moving to a notarized release.
- Submit the signed archive for notarization and staple the ticket.
- Keep `VMixCore` and `VMixMIDI` testable without attached MIDI hardware.
