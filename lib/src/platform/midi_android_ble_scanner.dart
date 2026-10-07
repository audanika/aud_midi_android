// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'midi_android_ble_scan_result.dart';

// #############################################################################
/// Scans for Bluetooth LE peripherals that advertise the BLE-MIDI service,
/// `BluetoothLeScanner` with a service UUID filter.
abstract interface class MidiAndroidBleScanner {
  // ...........................................................................
  /// Starts a scan; [onResult] and [onFailed] run later in this isolate.
  ///
  /// - [onFailed] gets the `ScanCallback` error code.
  void start({
    required void Function(MidiAndroidBleScanResult result) onResult,
    required void Function(int errorCode) onFailed,
  });

  /// Stops the running scan.
  void stop();

  // ...........................................................................
  /// Whether the Bluetooth adapter is switched on.
  bool get isEnabled;
}
