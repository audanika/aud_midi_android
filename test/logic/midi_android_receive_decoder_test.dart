// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  const decoder = MidiAndroidReceiveDecoder();

  Uint8List data(List<(int, List<int>)> chunks, {int dropped = 0}) {
    final builder = BytesBuilder()
      ..add((ByteData(4)..setInt32(0, dropped)).buffer.asUint8List());
    for (final (timestamp, bytes) in chunks) {
      builder
        ..add(
          (ByteData(12)
                ..setInt64(0, timestamp)
                ..setInt32(8, bytes.length))
              .buffer
              .asUint8List(),
        )
        ..add(bytes);
    }
    return builder.toBytes();
  }

  group('MidiAndroidReceiveDecoder', () {
    group('decode(data)', () {
      test('reads the dropped count and the chunks', () {
        final drained = decoder.decode(
          data([
            (123456789, [0x90, 0x3c, 0x64]),
            (0x7fffffffffff, [0xf8]),
          ], dropped: 2),
        );
        expect(drained.dropped, 2);
        expect(
          [
            for (final chunk in drained.chunks)
              [chunk.timestampNanos, chunk.bytes],
          ],
          [
            [
              123456789,
              [0x90, 0x3c, 0x64],
            ],
            [
              0x7fffffffffff,
              [0xf8],
            ],
          ],
        );
      });

      test('reads a drain without chunks', () {
        final drained = decoder.decode(data(const [], dropped: 7));
        expect(drained.dropped, 7);
        expect(drained.chunks, isEmpty);
      });

      for (final (name, bytes) in [
        ('a short header', Uint8List(3)),
        ('a short chunk header', Uint8List(10)),
        (
          'a short chunk',
          data([
            (1, [1, 2, 3]),
          ]).sublist(0, 18),
        ),
        (
          'a negative length',
          Uint8List.fromList([
            0, 0, 0, 0, //
            0, 0, 0, 0, 0, 0, 0, 1, //
            0xff, 0xff, 0xff, 0xff,
          ]),
        ),
      ]) {
        test('throws a FormatException for $name', () {
          expect(
            () => decoder.decode(bytes),
            throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'message',
                'Truncated receive data',
              ),
            ),
          );
        });
      }
    });

    group('headerSize, chunkHeaderSize', () {
      test('match AudMidiReceiver', () {
        expect(MidiAndroidReceiveDecoder.headerSize, 4);
        expect(MidiAndroidReceiveDecoder.chunkHeaderSize, 12);
      });
    });
  });
}
