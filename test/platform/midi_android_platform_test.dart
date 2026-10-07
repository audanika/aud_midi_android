// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidPlatform', () {
    test('is implemented with JNI, which needs Android', () {
      MidiAndroidPlatform create() => MidiAndroidJniPlatform();
      expect(create, throwsA(isA<MidiUnsupported>()));
    });
  });
}
