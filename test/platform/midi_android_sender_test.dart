// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidSender', () {
    group('amidi, java, virtual', () {
      test('name the paths of the data', () {
        expect(
          [
            MidiAndroidSender.amidi,
            MidiAndroidSender.java,
            MidiAndroidSender.virtual,
          ],
          ['amidi', 'java', 'virtual'],
        );
      });
    });

    group('send(data, {timestampNanos}), flush(), close(), kind', () {
      test('form the contract of a sender', () {
        final MidiAndroidSender sender = _Sender();
        sender
          ..send(Uint8List.fromList([0xf8]), timestampNanos: 5)
          ..flush()
          ..close();
        expect((sender as _Sender).calls, ['send f8 at 5', 'flush', 'close']);
        expect(sender.kind, MidiAndroidSender.java);
      });
    });
  });
}

// #############################################################################
final class _Sender implements MidiAndroidSender {
  final List<String> calls = [];

  @override
  void send(Uint8List data, {required int timestampNanos}) => calls.add(
    'send ${data.map((b) => b.toRadixString(16)).join(' ')} '
    'at $timestampNanos',
  );

  @override
  void flush() => calls.add('flush');

  @override
  void close() => calls.add('close');

  @override
  String get kind => MidiAndroidSender.java;
}
