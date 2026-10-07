// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:test/test.dart';

// The JNI glue runs on Android only; the example app verifies it on the
// emulator. On the development machine it must refuse cleanly.
void main() {
  group('MidiAndroidMulticastLock', () {
    group('MidiAndroidMulticastLock({tag, context})', () {
      test('throws MidiUnsupported outside Android', () {
        expect(
          MidiAndroidMulticastLock.new,
          throwsA(
            isA<MidiUnsupported>().having(
              (e) => e.feature,
              'feature',
              'WifiManager.MulticastLock outside Android',
            ),
          ),
        );
      });
    });
  });
}
