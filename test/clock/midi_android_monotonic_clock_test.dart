// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

@TestOn('mac-os')
library;

import 'dart:io';

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidMonotonicClock', () {
    group('nowMicros()', () {
      test('reads a monotonic clock in microseconds', () {
        // The development machine runs macOS, whose CLOCK_MONOTONIC is 6.
        final clock = MidiAndroidMonotonicClock(
          clockId: MidiAndroidMonotonicClock.clockMonotonicMacOs,
        );
        final before = clock.nowMicros();
        sleep(const Duration(milliseconds: 20));
        final elapsed = clock.nowMicros() - before;
        expect(elapsed, greaterThanOrEqualTo(20000));
        expect(elapsed, lessThan(2000000));
      });

      test('throws MidiNativeError for an unknown clock', () {
        // Clock 1, CLOCK_MONOTONIC of Android, does not exist on macOS.
        final clock = MidiAndroidMonotonicClock();
        expect(clock.clockId, MidiAndroidMonotonicClock.clockMonotonicAndroid);
        expect(
          clock.nowMicros,
          throwsA(
            isA<MidiNativeError>()
                .having((e) => e.api, 'api', 'clock_gettime(1)')
                .having((e) => e.code, 'code', -1),
          ),
        );
      });
    });
  });
}
