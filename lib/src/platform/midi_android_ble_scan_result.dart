// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
/// An advertisement of a Bluetooth LE MIDI peripheral, read from a
/// `ScanResult`.
final class MidiAndroidBleScanResult {
  /// Creates the result for the peripheral at [address].
  const MidiAndroidBleScanResult({
    required this.address,
    this.name = '',
    this.rssi,
    this.isConnectable = true,
  });

  // ...........................................................................
  /// The Bluetooth address of the peripheral.
  final String address;

  /// The advertised name, empty when unknown.
  final String name;

  /// The signal strength in dBm, or null when unknown.
  final int? rssi;

  /// Whether the peripheral accepts connections.
  final bool isConnectable;

  // ...........................................................................
  @override
  String toString() =>
      "MidiAndroidBleScanResult(address: '$address', name: '$name', "
      'rssi: $rssi, isConnectable: $isConnectable)';
}
