// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';
import 'package:test/test.dart';

void main() {
  const scan = 'android.permission.BLUETOOTH_SCAN';
  const connect = 'android.permission.BLUETOOTH_CONNECT';
  const bluetooth = 'android.permission.BLUETOOTH';
  const admin = 'android.permission.BLUETOOTH_ADMIN';
  const location = 'android.permission.ACCESS_FINE_LOCATION';
  const network = [
    'android.permission.INTERNET',
    'android.permission.CHANGE_WIFI_MULTICAST_STATE',
    'android.permission.ACCESS_WIFI_STATE',
  ];

  MidiAndroidPermissions permissions(int sdkInt, Set<String> granted) =>
      MidiAndroidPermissions(sdkInt: sdkInt, isGranted: granted.contains);

  final deniedBluetooth = throwsA(
    isA<MidiPermissionDenied>().having(
      (e) => e.permission,
      'permission',
      MidiPermission.bluetooth,
    ),
  );

  group('MidiAndroidPermissions', () {
    group('bluetoothScan, bluetoothConnect, localNetwork', () {
      test('follow the API level', () {
        expect(permissions(31, {}).bluetoothScan, [scan]);
        expect(permissions(30, {}).bluetoothScan, [bluetooth, admin, location]);
        expect(permissions(31, {}).bluetoothConnect, [connect]);
        expect(permissions(30, {}).bluetoothConnect, [bluetooth]);
        expect(permissions(36, {}).localNetwork, network);
        expect(permissions(36, {}).sdkInt, 36);
      });
    });

    group('missing', () {
      test('names the package permissions that lack a grant', () {
        expect(permissions(33, {}).missing, {
          MidiPermission.bluetooth,
          MidiPermission.localNetwork,
        });
        expect(permissions(33, {scan, ...network}).missing, {
          MidiPermission.bluetooth,
        });
        expect(permissions(33, {scan, connect, ...network}).missing, isEmpty);
        expect(permissions(30, {bluetooth, admin, location}).missing, {
          MidiPermission.localNetwork,
        });
      });
    });

    group('requireBluetoothScan(), requireBluetoothConnect()', () {
      test('throw without the permissions', () {
        expect(permissions(31, {}).requireBluetoothScan, deniedBluetooth);
        expect(permissions(31, {}).requireBluetoothConnect, deniedBluetooth);
        expect(
          permissions(30, {bluetooth}).requireBluetoothScan,
          deniedBluetooth,
        );
      });

      test('pass with the permissions', () {
        permissions(31, {scan, connect})
          ..requireBluetoothScan()
          ..requireBluetoothConnect();
      });
    });

    group('notGranted(permissions)', () {
      test('returns the permissions without a grant', () {
        expect(permissions(31, {scan}).notGranted([scan, connect]), [connect]);
      });
    });
  });
}
