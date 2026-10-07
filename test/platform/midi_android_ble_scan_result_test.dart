// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidBleScanResult', () {
    group('MidiAndroidBleScanResult({address, name, rssi, isConnectable})', () {
      test('describes a connectable peripheral without name by default', () {
        const result = MidiAndroidBleScanResult(address: 'AA');
        expect(result.address, 'AA');
        expect(result.name, '');
        expect(result.rssi, isNull);
        expect(result.isConnectable, isTrue);
      });
    });

    group('toString()', () {
      test('names all fields', () {
        expect(
          const MidiAndroidBleScanResult(
            address: 'AA',
            name: 'Keys',
            rssi: -50,
            isConnectable: false,
          ).toString(),
          "MidiAndroidBleScanResult(address: 'AA', name: 'Keys', rssi: -50, "
          'isConnectable: false)',
        );
      });
    });
  });
}
