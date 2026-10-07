// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// AMidi is internal to the package and not exported.
import 'package:aud_midi_android/src/amidi/midi_android_amidi.dart';
import 'package:test/test.dart';

// The FFI glue runs on Android only; the example app verifies it on the
// emulator. On the development machine it must not load.
void main() {
  group('MidiAndroidAMidi', () {
    group('load({sdkInt})', () {
      test('loads nothing outside Android and below API 29', () {
        expect(MidiAndroidAMidi.minSdk, 29);
        for (final sdkInt in [28, 29, 36]) {
          expect(MidiAndroidAMidi.load(sdkInt: sdkInt), isNull);
        }
      });
    });
  });
}
