# aud_midi_android

The Android backend of aud_midi: android.media.midi through JNI, AMidi through FFI, plus a small Java shim.

Part of the aud_midi family, see [aud_midi](https://github.com/audanika/aud_midi).

## Goals

- USB, Bluetooth LE and virtual devices
- MidiManager via jnigen, AMidi for timestamped I/O
- Java shim for abstract callback classes, no MethodChannel
- MidiDeviceService and MidiUmpDeviceService
- BLE peripheral through BluetoothGattServer

## State

Boilerplate only. The implementation follows in later tickets, see the plan in [aud_midi_pm](https://github.com/audanika/aud_midi_pm/blob/main/doc/2026-Q4/tickets/2026-10-06-aud_midi_01-initial-midi-implementation.md).

## Installation

```bash
dart pub add aud_midi_android
```

## Contributing

See [doc/guides/develop-guide.md](doc/guides/develop-guide.md).
