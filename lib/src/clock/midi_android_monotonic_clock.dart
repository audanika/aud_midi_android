// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:ffi/ffi.dart';

// #############################################################################
/// Reads a POSIX clock with `clock_gettime`, by default `CLOCK_MONOTONIC` of
/// Android, the clock of `System.nanoTime()` and of all MIDI timestamps.
final class MidiAndroidMonotonicClock {
  /// Creates a reader of the clock [clockId].
  MidiAndroidMonotonicClock({this.clockId = clockMonotonicAndroid});

  // ...........................................................................
  /// Returns the time of the clock in microseconds.
  ///
  /// Throws a [MidiNativeError] when `clock_gettime` fails, e.g. for an
  /// unknown clock.
  int nowMicros() {
    final result = _clockGettime(clockId, _time);
    if (result != 0) {
      throw MidiNativeError(api: 'clock_gettime($clockId)', code: result);
    }
    return _time.ref.seconds * 1000000 + _time.ref.nanoseconds ~/ 1000;
  }

  // ...........................................................................
  /// The id of the clock passed to `clock_gettime`.
  final int clockId;

  // ...........................................................................
  /// `CLOCK_MONOTONIC` on Android and Linux.
  static const int clockMonotonicAndroid = 1;

  /// `CLOCK_MONOTONIC` on macOS, for tests on the development machine.
  static const int clockMonotonicMacOs = 6;

  // ...........................................................................
  // One buffer per isolate, kept for the lifetime of the isolate.
  static final Pointer<_Timespec> _time = calloc<_Timespec>();

  static final int Function(int, Pointer<_Timespec>) _clockGettime =
      DynamicLibrary.process().lookupFunction<
        Int Function(Int, Pointer<_Timespec>),
        int Function(int, Pointer<_Timespec>)
      >('clock_gettime');
}

// #############################################################################
/// `struct timespec` of 64-bit POSIX systems.
final class _Timespec extends Struct {
  @Long()
  external int seconds;

  @Long()
  external int nanoseconds;
}
