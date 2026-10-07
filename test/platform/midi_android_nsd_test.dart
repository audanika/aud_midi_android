// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidNsd', () {
    group('register(...)', () {
      test('returns the function that unregisters', () {
        final events = <String>[];
        final MidiAndroidNsd nsd = _Nsd();
        final unregister = nsd.register(
          name: 'S',
          type: '_apple-midi._udp',
          port: 5004,
          txt: const {},
          onRegistered: (name) => events.add('registered $name'),
          onRegistrationFailed: (code) => events.add('failed $code'),
          onUnregistered: () => events.add('unregistered'),
          onUnregistrationFailed: (code) => events.add('not $code'),
        );
        unregister();
        expect(events, ['registered S (2)', 'unregistered']);
      });
    });
  });
}

// #############################################################################
final class _Nsd implements MidiAndroidNsd {
  @override
  void Function() register({
    required String name,
    required String type,
    required int port,
    required Map<String, String> txt,
    required void Function(String name) onRegistered,
    required void Function(int errorCode) onRegistrationFailed,
    required void Function() onUnregistered,
    required void Function(int errorCode) onUnregistrationFailed,
  }) {
    onRegistered('$name (2)');
    return onUnregistered;
  }
}
