// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';

// #############################################################################
/// The Android permissions the backend needs, per API level.
///
/// The app declares them in its manifest and requests the runtime ones
/// itself; the backend only checks them.
final class MidiAndroidPermissions {
  /// Creates the permission logic for API level [sdkInt]; [isGranted]
  /// tells whether the app holds an Android permission.
  const MidiAndroidPermissions({required this.sdkInt, required this.isGranted});

  // ...........................................................................
  /// Throws [MidiPermissionDenied] when a permission of [bluetoothScan] is
  /// missing.
  void requireBluetoothScan() =>
      _require(bluetoothScan, MidiPermission.bluetooth);

  /// Throws [MidiPermissionDenied] when a permission of [bluetoothConnect]
  /// is missing.
  void requireBluetoothConnect() =>
      _require(bluetoothConnect, MidiPermission.bluetooth);

  /// Returns the permissions of [permissions] the app does not hold.
  List<String> notGranted(List<String> permissions) =>
      permissions.where((permission) => !isGranted(permission)).toList();

  // ...........................................................................
  /// The API level.
  final int sdkInt;

  /// Tells whether the app holds an Android permission.
  final bool Function(String permission) isGranted;

  /// The permissions a Bluetooth LE scan needs: `BLUETOOTH_SCAN` from API
  /// 31, before that `BLUETOOTH`, `BLUETOOTH_ADMIN` and
  /// `ACCESS_FINE_LOCATION`.
  List<String> get bluetoothScan => sdkInt >= 31
      ? const [_bluetoothScan]
      : const [_bluetooth, _bluetoothAdmin, _fineLocation];

  /// The permissions a Bluetooth LE connection needs: `BLUETOOTH_CONNECT`
  /// from API 31, before that `BLUETOOTH`.
  List<String> get bluetoothConnect =>
      sdkInt >= 31 ? const [_bluetoothConnect] : const [_bluetooth];

  /// The permissions network sessions need: `INTERNET`,
  /// `CHANGE_WIFI_MULTICAST_STATE` for the multicast lock and
  /// `ACCESS_WIFI_STATE`.
  List<String> get localNetwork => const [
    'android.permission.INTERNET',
    'android.permission.CHANGE_WIFI_MULTICAST_STATE',
    'android.permission.ACCESS_WIFI_STATE',
  ];

  /// The package permissions with at least one missing Android permission.
  Set<MidiPermission> get missing => {
    if (notGranted([...bluetoothScan, ...bluetoothConnect]).isNotEmpty)
      MidiPermission.bluetooth,
    if (notGranted(localNetwork).isNotEmpty) MidiPermission.localNetwork,
  };

  // ...........................................................................
  static const _bluetooth = 'android.permission.BLUETOOTH';
  static const _bluetoothAdmin = 'android.permission.BLUETOOTH_ADMIN';
  static const _bluetoothScan = 'android.permission.BLUETOOTH_SCAN';
  static const _bluetoothConnect = 'android.permission.BLUETOOTH_CONNECT';
  static const _fineLocation = 'android.permission.ACCESS_FINE_LOCATION';

  void _require(List<String> permissions, MidiPermission permission) {
    if (notGranted(permissions).isNotEmpty) {
      throw MidiPermissionDenied(permission);
    }
  }
}
