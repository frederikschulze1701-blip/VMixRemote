<!-- SPDX-License-Identifier: Apache-2.0 -->

# VMixRemote macOS Architecture

## Projektstruktur

- `Sources/VMixCore`: plattformneutraler Mixer-Core ohne SwiftUI, AppKit oder CoreMIDI.
- `Sources/VMixCore/MIDI`: MIDI-Nachrichten, Encoding/Decoding und UI-Parameter-Mapping.
- `Sources/VMixCore/Persistence`: Codable-Profile, Default-Profil, Import/Export und Legacy-Pfad-Migration.
- `Sources/VMixMIDI`: `MIDIBackend`-Protokoll, Mock-Backend und CoreMIDI-Backend.
- `Sources/VMixRemoteApp`: SwiftUI-macOS-App, ViewModels und wiederverwendbare Views.
- `Tests/VMixCoreTests`: Core-, MIDI-Codec-, Profil- und State-Tests.
- `Tests/VMixMIDITests`: Mock-MIDI-Kommunikationstests.
- `script/build_and_run.sh`: SwiftPM-Build plus lokale `.app`-Bundle-Staging-Hülle.
- `Packaging`: spätere Signierung, Icon- und Notarisierungsnotizen.

## Architektur

Die App ist in drei harte Schichten getrennt:

1. `VMixCore` modelliert Mixer, Channel, Fader, EQ, Szenen/Profile und MIDI-Mapping als Codable-Werte.
2. `VMixMIDI` kapselt Hardware-Kommunikation hinter `MIDIBackend`, damit CoreMIDI und Mock-MIDI austauschbar bleiben.
3. `VMixRemoteApp` hält SwiftUI, AppKit-Panels und ViewModels. UI-Interaktionen erzeugen `MixerParameterUpdate`, die zuerst den Core-State ändern und danach optional MIDI senden.

## MVP

Das MVP enthält acht Channel-Strips, Fader, Mute, Solo, Select, Mock-MIDI, einfache Gerätelisten, Profil-Speichern/Laden, Import/Export und eine CoreMIDI-Schicht, die ohne angeschlossene Hardware leer bleiben darf.

## Offene Risiken

- Die alte 02R-SysEx-Logik ist noch nicht vollständig portiert; aktuell gibt es generische CC/Note-Mappings plus SysEx-Decoding als Nachrichtentyp.
- Fader-Kurven sind im MVP linear normalisiert. Die alte 02R-Lin/Exp-LUT sollte als mixer-spezifische Kurve nachgezogen werden.
- CoreMIDI-SysEx-Fragmente können auf realer Hardware paketweise eintreffen; dafür braucht es noch einen Reassembler.
- App-Icon, Signing, Hardened Runtime und Notarisierung sind vorbereitet, aber noch nicht produktionsreif abgeschlossen.

## Roadmap

1. Yamaha-02R-SysEx-Encoder/Decoder aus `MidiManager02r.cs` in Swift portieren und mit Fixture-Tests absichern.
2. Fader-Kurven als Strategie pro Mixer-Profil implementieren.
3. Hotplug-UX erweitern: verlorene Geräte anzeigen, Reconnect anbieten, zuletzt genutzte Geräte persistieren.
4. EQ-Editor grafisch ausbauen und Mappings für EQ/Pan/Sends ergänzen.
5. App-Icon als `.icns`/Asset Catalog hinzufügen, Release-Konfiguration, Signing und Notarisierung dokumentieren.
