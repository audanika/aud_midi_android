# aud_midi_android

The Android backend of aud_midi: android.media.midi through JNI, AMidi through FFI, plus a small Java shim.

Part of the aud_midi family, see [aud_midi](https://github.com/audanika/aud_midi).

## Goals

- USB, Bluetooth LE and virtual devices
- MidiManager via jnigen, AMidi for timestamped I/O
- Java shim for abstract callback classes, no MethodChannel
- MidiDeviceService and MidiUmpDeviceService

## State

Boilerplate only. The implementation follows in later tickets, see the plan in [aud_midi](https://github.com/audanika/aud_midi/blob/main/blog/2026/10/01_plan_the_package_implementation.md).

## Installation

```bash
dart pub add aud_midi_android
```

## Contributing

See [doc/guides/develop-guide.md](doc/guides/develop-guide.md).
