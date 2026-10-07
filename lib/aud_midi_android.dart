// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// The Android backend of the aud_midi family: `android.media.midi` through
/// jnigen bindings and a small Java shim, AMidi through FFI for sending,
/// Bluetooth LE MIDI, the app's static virtual devices and `NsdManager`
/// advertising.
library;

export 'src/android_midi_backend.dart';
export 'src/bluetooth/midi_android_bluetooth.dart';
export 'src/clock/midi_android_monotonic_clock.dart';
export 'src/jni/midi_android_jni_nsd.dart';
export 'src/jni/midi_android_jni_platform.dart';
export 'src/jni/midi_android_multicast_lock.dart';
export 'src/logic/midi_android_error_codes.dart';
export 'src/logic/midi_android_packet_encoder.dart';
export 'src/logic/midi_android_permissions.dart';
export 'src/logic/midi_android_port_mapper.dart';
export 'src/logic/midi_android_port_table.dart';
export 'src/logic/midi_android_receive_decoder.dart';
export 'src/logic/midi_android_ump_assembler.dart';
export 'src/network/midi_android_service_advertiser.dart';
export 'src/platform/midi_android_ble_scan_result.dart';
export 'src/platform/midi_android_ble_scanner.dart';
export 'src/platform/midi_android_device.dart';
export 'src/platform/midi_android_device_description.dart';
export 'src/platform/midi_android_nsd.dart';
export 'src/platform/midi_android_platform.dart';
export 'src/platform/midi_android_port_description.dart';
export 'src/platform/midi_android_receiver.dart';
export 'src/platform/midi_android_sender.dart';
export 'src/virtual/midi_android_virtual_ports.dart';
