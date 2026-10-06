# aud_midi_android

Das Android-Backend von aud_midi: android.media.midi über JNI, AMidi über FFI, dazu ein kleiner Java-Shim.

Teil der aud_midi-Familie, siehe [aud_midi](https://github.com/audanika/aud_midi).

## Ziele

- USB, Bluetooth LE und virtuelle Geräte
- MidiManager über jnigen, AMidi für I/O mit Zeitstempeln
- Java-Shim für abstrakte Callback-Klassen, kein MethodChannel
- MidiDeviceService und MidiUmpDeviceService

## Stand

Nur Boilerplate. Die Implementierung folgt in späteren Tickets, siehe den Plan in [aud_midi](https://github.com/audanika/aud_midi/blob/main/blog/2026/10/01_plan_the_package_implementation.md).

## Installation

```bash
dart pub add aud_midi_android
```

## Mitwirken

Siehe [doc/guides/develop-guide.md](doc/guides/develop-guide.md).
