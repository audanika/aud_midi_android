// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidPortDescription', () {
    group('MidiAndroidPortDescription({type, number, name})', () {
      test('describes a port without a name by default', () {
        const port = MidiAndroidPortDescription(
          type: MidiAndroidPortDescription.typeOutput,
          number: 2,
        );
        expect(port.type, 2);
        expect(port.number, 2);
        expect(port.name, '');
      });
    });

    group('isInput', () {
      test('tells the Android input ports', () {
        for (final (type, isInput) in [
          (MidiAndroidPortDescription.typeInput, true),
          (MidiAndroidPortDescription.typeOutput, false),
        ]) {
          expect(
            MidiAndroidPortDescription(type: type, number: 0).isInput,
            isInput,
          );
        }
      });
    });

    group('typeInput, typeOutput', () {
      test('match PortInfo', () {
        expect(MidiAndroidPortDescription.typeInput, 1);
        expect(MidiAndroidPortDescription.typeOutput, 2);
      });
    });

    group('toString()', () {
      test('names all fields', () {
        expect(
          const MidiAndroidPortDescription(
            type: 1,
            number: 0,
            name: 'In',
          ).toString(),
          "MidiAndroidPortDescription(type: 1, number: 0, name: 'In')",
        );
      });
    });
  });
}
