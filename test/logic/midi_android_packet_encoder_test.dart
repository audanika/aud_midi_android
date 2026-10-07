// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';
import 'package:test/test.dart';

void main() {
  const encoder = MidiAndroidPacketEncoder(maxChunk: 16);

  group('MidiAndroidPacketEncoder', () {
    group('MidiAndroidPacketEncoder({maxChunk})', () {
      test('defaults to 1012 bytes and asserts 16 at least', () {
        expect(const MidiAndroidPacketEncoder().maxChunk, 1012);
        expect(MidiAndroidPacketEncoder.defaultMaxChunk, 1012);
        expect(
          () => MidiAndroidPacketEncoder(maxChunk: 15),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('encode(packet)', () {
      test('splits bytes into chunks of maxChunk', () {
        final bytes = [for (var i = 0; i < 40; i++) i];
        expect(
          encoder.encode(
            MidiBytesPacket(bytes: MidiBytes(bytes), time: MidiTime.zero),
          ),
          [bytes.sublist(0, 16), bytes.sublist(16, 32), bytes.sublist(32)],
        );
      });

      test('returns no chunk for an empty packet', () {
        expect(
          encoder.encode(
            MidiBytesPacket(bytes: MidiBytes.empty, time: MidiTime.zero),
          ),
          isEmpty,
        );
        expect(
          encoder.encode(MidiUmpPacket(words: const [], time: MidiTime.zero)),
          isEmpty,
        );
      });

      test('splits UMP words between packets only', () {
        final chunks = encoder.encode(
          MidiUmpPacket(
            words: const [
              0x20903c64, // 1 word
              0x40903c00, 0xc0000000, // 2 words
              0xf0000101, 0x1f, 0, 0, // 4 words
              0x00000000, // 1 word
            ],
            time: MidiTime.zero,
          ),
        );
        expect(chunks, [
          [0x20, 0x90, 0x3c, 0x64, 0x40, 0x90, 0x3c, 0x00, 0xc0, 0, 0, 0],
          [0xf0, 0x00, 0x01, 0x01, 0, 0, 0, 0x1f, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0],
        ]);
      });

      test('throws an ArgumentError for an incomplete last UMP', () {
        expect(
          () => encoder.encode(
            MidiUmpPacket(words: const [0x40903c00], time: MidiTime.zero),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Incomplete last UMP',
            ),
          ),
        );
      });
    });

    group('pack(words)', () {
      test('writes the low 32 bits big-endian', () {
        expect(MidiAndroidPacketEncoder.pack([0x1ffffffff, 0x01020304]), [
          0xff, 0xff, 0xff, 0xff, //
          0x01, 0x02, 0x03, 0x04,
        ]);
      });
    });
  });
}
