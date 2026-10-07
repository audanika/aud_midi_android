// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidReceiver', () {
    group('drain(), close()', () {
      test('deliver data in the layout of the receive decoder', () {
        final MidiAndroidReceiver receiver = _Receiver();
        final drained = const MidiAndroidReceiveDecoder().decode(
          receiver.drain()!,
        );
        expect(drained.chunks.single.bytes, [0xf8]);
        expect(drained.chunks.single.timestampNanos, 9);
        expect(receiver.drain(), isNull);
        receiver.close();
        expect((receiver as _Receiver).closed, isTrue);
      });
    });
  });
}

// #############################################################################
final class _Receiver implements MidiAndroidReceiver {
  final List<Uint8List> _queue = [
    Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 1, 0xf8]),
  ];
  bool closed = false;

  @override
  Uint8List? drain() => _queue.isEmpty ? null : _queue.removeAt(0);

  @override
  void close() => closed = true;
}
