// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';

import '../logic/midi_android_permissions.dart';
import '../platform/midi_android_ble_scan_result.dart';
import '../platform/midi_android_ble_scanner.dart';

// #############################################################################
/// Finds Bluetooth LE MIDI peripherals and connects them through
/// `MidiManager.openBluetoothDevice`.
///
/// Android has no automatic connection for BLE-MIDI: the app scans with a
/// filter for the BLE-MIDI service and opens the peripheral it wants; the
/// MIDI service then provides it as an ordinary MIDI device.
final class MidiAndroidBluetooth implements MidiBluetoothBackend {
  /// Creates the Bluetooth support.
  ///
  /// - [scanner] scans for advertisements.
  /// - [permissions] checks the Bluetooth permissions.
  /// - [connectPeripheral] opens the peripheral at an address and returns
  ///   its ports.
  /// - [disconnectPeripheral] closes the peripheral at an address.
  /// - [onScanFailed] learns the error code of a scan that failed.
  MidiAndroidBluetooth({
    required this._scanner,
    required this._permissions,
    required this._connectPeripheral,
    required this._disconnectPeripheral,
    required this._onScanFailed,
  });

  // ...........................................................................
  /// Scans for peripherals that advertise the BLE-MIDI service.
  ///
  /// A new scan ends the one before. The stream reports a peripheral when
  /// it is seen first and when its name or connectability changes.
  ///
  /// Throws [MidiPermissionDenied] without the scan permissions and
  /// [MidiUnsupported] while Bluetooth is switched off.
  @override
  Stream<MidiBlePeripheralInfo> scan({Duration? timeout}) {
    _permissions.requireBluetoothScan();
    if (!_scanner.isEnabled) {
      throw const MidiUnsupported('Bluetooth LE while Bluetooth is off');
    }
    _finishScan();
    final controller = StreamController<MidiBlePeripheralInfo>();
    controller.onCancel = _finishScan;
    _controller = controller;
    _found.clear();
    _scanner.start(onResult: _onResult, onFailed: _onFailed);
    if (timeout != null) _timer = Timer(timeout, _finishScan);
    return controller.stream;
  }

  @override
  Future<void> stopScan() async => _finishScan();

  /// Connects the peripheral with the Bluetooth address [peripheralId].
  ///
  /// Throws [MidiPermissionDenied] without the connect permission and a
  /// `MidiNativeError` when Android cannot open the peripheral within
  /// [timeout].
  @override
  Future<List<MidiPortInfo>> connect(
    String peripheralId, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _permissions.requireBluetoothConnect();
    return _connectPeripheral(peripheralId, timeout);
  }

  @override
  Future<void> disconnect(String peripheralId) =>
      _disconnectPeripheral(peripheralId);

  // ...........................................................................
  /// Whether a scan runs.
  bool get isScanning => _controller != null;

  // ...........................................................................
  final MidiAndroidBleScanner _scanner;
  final MidiAndroidPermissions _permissions;
  final Future<List<MidiPortInfo>> Function(String address, Duration timeout)
  _connectPeripheral;
  final Future<void> Function(String address) _disconnectPeripheral;
  final void Function(int errorCode) _onScanFailed;
  final Map<String, MidiBlePeripheralInfo> _found = {};
  StreamController<MidiBlePeripheralInfo>? _controller;
  Timer? _timer;

  void _onResult(MidiAndroidBleScanResult result) {
    final controller = _controller;
    if (controller == null) return;
    final info = MidiBlePeripheralInfo(
      id: result.address,
      name: result.name,
      rssi: result.rssi,
      isConnectable: result.isConnectable,
    );
    final previous = _found[result.address];
    _found[result.address] = info;
    if (previous == null ||
        previous.name != info.name ||
        previous.isConnectable != info.isConnectable) {
      controller.add(info);
    }
  }

  void _onFailed(int errorCode) {
    _onScanFailed(errorCode);
    _finishScan();
  }

  void _finishScan() {
    _timer?.cancel();
    _timer = null;
    final controller = _controller;
    if (controller == null) return;
    _controller = null;
    _scanner.stop();
    unawaited(controller.close());
  }
}
