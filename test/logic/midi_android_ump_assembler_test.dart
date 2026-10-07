// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  late MidiAndroidUmpAssembler assembler;

  List<int> add(List<int> bytes) =>
      assembler.add(Uint8List.fromList(bytes)).toList();

  setUp(() => assembler = MidiAndroidUmpAssembler());

  group('MidiAndroidUmpAssembler', () {
    group('add(bytes)', () {
      test('reads big-endian words of complete packets', () {
        expect(
          add([
            0x20, 0x90, 0x3c, 0x64, //
            0x40, 0x90, 0x3c, 0x00, 0xc0, 0x00, 0x00, 0x00,
          ]),
          [0x20903c64, 0x40903c00, 0xc0000000],
        );
        expect(assembler.pending, 0);
      });

      test('keeps a word that ends in the next chunk', () {
        expect(add([0x20, 0x90]), isEmpty);
        expect(assembler.pending, 2);
        expect(add([0x3c, 0x64]), [0x20903c64]);
      });

      test('keeps a packet that ends in the next chunk', () {
        expect(
          add([
            0xf0, 0x00, 0x01, 0x01, //
            0x00, 0x00, 0x00, 0x1f, //
            0x00, 0x00,
          ]),
          isEmpty,
        );
        expect(assembler.pending, 10);
        expect(
          add([
            0x00, 0x00, //
            0x00, 0x00, 0x00, 0x00, //
            0x00, 0x00, 0x00, 0x00, // a NOOP after the stream message
          ]),
          [0xf0000101, 0x0000001f, 0, 0, 0],
        );
      });
    });

    group('reset()', () {
      test('drops the rest', () {
        add([0x40, 0x90, 0x3c, 0x00]);
        assembler.reset();
        expect(assembler.pending, 0);
        expect(add([0x20, 0x90, 0x3c, 0x64]), [0x20903c64]);
      });
    });
  });
}
