// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidDevice', () {
    group('open…Port(), close(), description', () {
      test('form the contract of an opened device', () {
        final MidiAndroidDevice device = _Device();
        expect(device.description.id, 1);
        expect(device.openOutputPort(port: 0, onData: () {}), isNull);
        expect(device.openNativeInputPort(0), isNull);
        expect(device.openJavaInputPort(0), isNull);
        device.close();
        expect((device as _Device).closed, isTrue);
      });
    });
  });
}

// #############################################################################
final class _Device implements MidiAndroidDevice {
  bool closed = false;

  @override
  final MidiAndroidDeviceDescription description =
      const MidiAndroidDeviceDescription(id: 1, type: 1);

  @override
  MidiAndroidReceiver? openOutputPort({
    required int port,
    required void Function() onData,
  }) => null;

  @override
  MidiAndroidSender? openNativeInputPort(int port) => null;

  @override
  MidiAndroidSender? openJavaInputPort(int port) => null;

  @override
  void close() => closed = true;
}
