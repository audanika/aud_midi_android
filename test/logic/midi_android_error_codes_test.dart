// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidErrorCodes', () {
    test('stay clear of Android codes', () {
      // NsdManager failures are positive, media_status_t errors below -10000.
      expect(MidiAndroidErrorCodes.unavailable, -1);
      expect(MidiAndroidErrorCodes.timeout, -2);
    });
  });
}
