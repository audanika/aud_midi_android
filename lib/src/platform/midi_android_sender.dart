// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

// #############################################################################
/// An open way to send data into an Android MIDI port: AMidi, a Java
/// `MidiInputPort` or an output port of the app's own virtual device.
abstract interface class MidiAndroidSender {
  // ...........................................................................
  /// Sends [data] due at [timestampNanos] on `CLOCK_MONOTONIC`.
  ///
  /// Throws a `MidiNativeError` when Android refuses the data.
  void send(Uint8List data, {required int timestampNanos});

  /// Discards the data sent before that are not due yet.
  void flush();

  /// Closes the port; the sender cannot be used afterwards.
  void close();

  // ...........................................................................
  /// The path the data take: [amidi], [java] or [virtual].
  String get kind;

  // ...........................................................................
  /// The [kind] of a sender that uses AMidi (API 29).
  static const String amidi = 'amidi';

  /// The [kind] of a sender that uses `MidiInputPort`.
  static const String java = 'java';

  /// The [kind] of a sender out of the app's own virtual device.
  static const String virtual = 'virtual';
}
