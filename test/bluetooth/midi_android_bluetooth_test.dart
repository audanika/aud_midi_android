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
  const scanPermission = 'android.permission.BLUETOOTH_SCAN';
  const connectPermission = 'android.permission.BLUETOOTH_CONNECT';
  const keys = MidiAndroidBleScanResult(address: 'A', name: 'Keys', rssi: -40);

  late _FakeScanner scanner;
  late Set<String> granted;
  late List<(String, Duration)> connects;
  late List<String> disconnects;
  late List<int> failures;
  late MidiAndroidBluetooth bluetooth;

  setUp(() {
    scanner = _FakeScanner();
    granted = {scanPermission, connectPermission};
    connects = [];
    disconnects = [];
    failures = [];
    bluetooth = MidiAndroidBluetooth(
      scanner: scanner,
      permissions: MidiAndroidPermissions(
        sdkInt: 33,
        isGranted: (permission) => granted.contains(permission),
      ),
      connectPeripheral: (address, timeout) async {
        connects.add((address, timeout));
        return const [];
      },
      disconnectPeripheral: (address) async => disconnects.add(address),
      onScanFailed: failures.add,
    );
  });

  group('MidiAndroidBluetooth', () {
    group('scan({timeout})', () {
      test('reports new peripherals and changes of name', () async {
        final found = bluetooth.scan().toList();
        expect(bluetooth.isScanning, isTrue);
        scanner
          ..report(keys)
          ..report(
            const MidiAndroidBleScanResult(
              address: 'A',
              name: 'Keys',
              rssi: -60,
            ),
          )
          ..report(const MidiAndroidBleScanResult(address: 'A', name: 'Keys 2'))
          ..report(
            const MidiAndroidBleScanResult(
              address: 'A',
              name: 'Keys 2',
              isConnectable: false,
            ),
          )
          ..report(const MidiAndroidBleScanResult(address: 'B'));
        await bluetooth.stopScan();
        expect(await found, [
          MidiBlePeripheralInfo(id: 'A', name: 'Keys', rssi: -40),
          MidiBlePeripheralInfo(id: 'A', name: 'Keys 2'),
          MidiBlePeripheralInfo(id: 'A', name: 'Keys 2', isConnectable: false),
          MidiBlePeripheralInfo(id: 'B'),
        ]);
        expect(scanner.stops, 1);
        expect(bluetooth.isScanning, isFalse);
      });

      test('ends after the timeout', () async {
        final found = bluetooth.scan(timeout: Duration.zero).toList();
        expect(await found, isEmpty);
        expect(scanner.stops, 1);
      });

      test('ends the scan before', () async {
        final first = bluetooth.scan().toList();
        final second = bluetooth.scan().toList();
        scanner.report(keys);
        await bluetooth.stopScan();
        expect(await first, isEmpty);
        expect((await second).single.id, 'A');
        expect(scanner.starts, 2);
      });

      test('ends when the listener cancels', () async {
        final subscription = bluetooth.scan().listen((_) {});
        await subscription.cancel();
        expect(scanner.stops, 1);
        scanner.report(keys);
      });

      test('ends and reports when the scan fails', () async {
        final found = bluetooth.scan().toList();
        scanner.fail(2);
        expect(await found, isEmpty);
        expect(failures, [2]);
      });

      test('throws without the scan permission', () {
        granted.remove(scanPermission);
        expect(
          () => bluetooth.scan(),
          throwsA(
            isA<MidiPermissionDenied>().having(
              (e) => e.permission,
              'permission',
              MidiPermission.bluetooth,
            ),
          ),
        );
      });

      test('throws while Bluetooth is off', () {
        scanner.isEnabled = false;
        expect(() => bluetooth.scan(), throwsA(isA<MidiUnsupported>()));
      });
    });

    group('connect(peripheralId, {timeout})', () {
      test('connects through the backend', () async {
        await bluetooth.connect('A', timeout: const Duration(seconds: 3));
        await bluetooth.connect('B');
        expect(connects, [
          ('A', const Duration(seconds: 3)),
          ('B', const Duration(seconds: 10)),
        ]);
      });

      test('throws without the connect permission', () async {
        granted.remove(connectPermission);
        await expectLater(
          bluetooth.connect('A'),
          throwsA(isA<MidiPermissionDenied>()),
        );
        expect(connects, isEmpty);
      });
    });

    group('disconnect(peripheralId)', () {
      test('disconnects through the backend', () async {
        await bluetooth.disconnect('A');
        expect(disconnects, ['A']);
      });
    });
  });
}

// #############################################################################
final class _FakeScanner implements MidiAndroidBleScanner {
  @override
  bool isEnabled = true;

  int starts = 0;
  int stops = 0;
  void Function(MidiAndroidBleScanResult result)? _onResult;
  void Function(int errorCode)? _onFailed;

  void report(MidiAndroidBleScanResult result) => _onResult?.call(result);

  void fail(int errorCode) => _onFailed?.call(errorCode);

  @override
  void start({
    required void Function(MidiAndroidBleScanResult result) onResult,
    required void Function(int errorCode) onFailed,
  }) {
    starts++;
    _onResult = onResult;
    _onFailed = onFailed;
  }

  @override
  void stop() => stops++;
}
