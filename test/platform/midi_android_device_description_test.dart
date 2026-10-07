// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidDeviceDescription', () {
    group('MidiAndroidDeviceDescription(...)', () {
      test('describes a byte-stream device by default', () {
        const device = MidiAndroidDeviceDescription(id: 1, type: 1);
        expect(
          device.transport,
          MidiAndroidDeviceDescription.transportByteStream,
        );
        expect(
          device.defaultProtocol,
          MidiAndroidDeviceDescription.protocolUnknown,
        );
        expect(
          [
            device.name,
            device.manufacturer,
            device.product,
            device.serialNumber,
            device.version,
            device.bluetoothAddress,
          ],
          ['', '', '', '', '', ''],
        );
        expect(device.ports, isEmpty);
        expect(device.ownService, isNull);
        expect(device.isPrivate, isFalse);
        expect(device.isUmp, isFalse);
      });
    });

    group('isUmp', () {
      test('tells UMP devices', () {
        const device = MidiAndroidDeviceDescription(
          id: 1,
          type: 1,
          transport: MidiAndroidDeviceDescription.transportUmp,
        );
        expect(device.isUmp, isTrue);
      });
    });

    group('constants', () {
      test('match MidiDeviceInfo and MidiManager', () {
        expect(
          [
            MidiAndroidDeviceDescription.typeUsb,
            MidiAndroidDeviceDescription.typeVirtual,
            MidiAndroidDeviceDescription.typeBluetooth,
            MidiAndroidDeviceDescription.transportByteStream,
            MidiAndroidDeviceDescription.transportUmp,
            MidiAndroidDeviceDescription.protocolUnknown,
            MidiAndroidDeviceDescription.protocolUseMidiCi,
            MidiAndroidDeviceDescription.protocolMidi1UpTo64Bits,
            MidiAndroidDeviceDescription.protocolMidi1UpTo64BitsAndJrts,
            MidiAndroidDeviceDescription.protocolMidi1UpTo128Bits,
            MidiAndroidDeviceDescription.protocolMidi1UpTo128BitsAndJrts,
            MidiAndroidDeviceDescription.protocolMidi2,
            MidiAndroidDeviceDescription.protocolMidi2AndJrts,
          ],
          [1, 2, 3, 1, 2, -1, 0, 1, 2, 3, 4, 17, 18],
        );
      });
    });

    group('toString()', () {
      test('names all fields', () {
        const device = MidiAndroidDeviceDescription(
          id: 4,
          type: 3,
          name: 'N',
          ports: [MidiAndroidPortDescription(type: 1, number: 0)],
          bluetoothAddress: 'AA',
        );
        expect(
          device.toString(),
          'MidiAndroidDeviceDescription(id: 4, type: 3, transport: 1, '
          "defaultProtocol: -1, name: 'N', manufacturer: '', product: '', "
          "serialNumber: '', version: '', ports: "
          "[MidiAndroidPortDescription(type: 1, number: 0, name: '')], "
          "ownService: null, bluetoothAddress: 'AA', isPrivate: false)",
        );
      });
    });
  });
}
