// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'midi_android_ble_scanner.dart';
import 'midi_android_device.dart';
import 'midi_android_device_description.dart';
import 'midi_android_receiver.dart';
import 'midi_android_sender.dart';

// #############################################################################
/// The Android side of the backend: what `android.media.midi`, the Java shim
/// and AMidi offer, reduced to plain Dart.
///
/// `AndroidMidiBackend` reaches Android only through this interface. The
/// package implements it with JNI and FFI; tests implement it with fakes.
abstract interface class MidiAndroidPlatform {
  // ...........................................................................
  /// Returns the devices the MIDI service knows, of both transports.
  List<MidiAndroidDeviceDescription> devices();

  /// Reports devices that appear ([onAdded]) or disappear ([onRemoved], with
  /// the device id) until [unwatchDevices]; the callbacks run later in this
  /// isolate.
  void watchDevices({
    required void Function(MidiAndroidDeviceDescription device) onAdded,
    required void Function(int id) onRemoved,
  });

  /// Stops reporting devices.
  void unwatchDevices();

  // ...........................................................................
  /// Opens the device [id]; completes with null when Android cannot open
  /// it.
  Future<MidiAndroidDevice?> openDevice(int id);

  /// Connects the Bluetooth LE MIDI peripheral at [address] and opens it;
  /// completes with null when Android cannot open it.
  Future<MidiAndroidDevice?> openBluetoothDevice(String address);

  // ...........................................................................
  /// Returns the receiver of what other apps send to input [port] of the
  /// app's own virtual device of [service].
  ///
  /// - [onData] runs in this isolate whenever data wait in the receiver.
  MidiAndroidReceiver openVirtualInput({
    required String service,
    required int port,
    required void Function() onData,
  });

  /// Returns a sender out of output [port] of the app's own virtual device
  /// of [service].
  MidiAndroidSender openVirtualOutput({
    required String service,
    required int port,
  });

  // ...........................................................................
  /// Returns whether the app holds the Android [permission], e.g.
  /// `android.permission.BLUETOOTH_SCAN`.
  bool hasPermission(String permission);

  /// Returns the time of `CLOCK_MONOTONIC` in microseconds, the clock of
  /// Android's MIDI timestamps.
  int monotonicMicros();

  /// Releases the listeners the platform holds.
  void dispose();

  // ...........................................................................
  /// The API level, `Build.VERSION.SDK_INT`.
  int get sdkInt;

  /// Whether the device supports MIDI, feature `android.software.midi`.
  bool get hasMidi;

  /// The Bluetooth LE scanner, or null without Bluetooth LE.
  MidiAndroidBleScanner? get bleScanner;
}
