// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

// #############################################################################
/// An open Android MIDI port that delivers data to the app through the
/// shim's `AudMidiReceiver`.
abstract interface class MidiAndroidReceiver {
  // ...........................................................................
  /// Returns everything received since the last call in the layout of
  /// `AudMidiReceiver.drain()`, or null when nothing arrived.
  Uint8List? drain();

  /// Stops the delivery and closes the port.
  void close();
}
