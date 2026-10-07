// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

/**
 * Learns that an {@link AudMidiReceiver} holds new data. Dart implements it as
 * a listener, so the MIDI thread that calls it never waits for Dart.
 */
public interface AudMidiDataListener {
  /**
   * Called once when the receiver with {@code token} gets data after its last
   * drain; the listener then calls {@link AudMidiReceiver#drain()}.
   */
  void onDataAvailable(int token);
}
