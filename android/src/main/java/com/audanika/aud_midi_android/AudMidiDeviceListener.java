// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import android.media.midi.MidiDeviceInfo;

/**
 * Learns about MIDI devices that appear or disappear. Dart implements it as a
 * listener behind {@link AudMidiDeviceCallback}.
 */
public interface AudMidiDeviceListener {
  /**
   * Called when {@code device} appeared; {@code transport} is
   * {@code MidiManager.TRANSPORT_MIDI_BYTE_STREAM} or
   * {@code TRANSPORT_UNIVERSAL_MIDI_PACKETS}.
   */
  void onDeviceAdded(MidiDeviceInfo device, int transport);

  /** Called when {@code device} disappeared. */
  void onDeviceRemoved(MidiDeviceInfo device, int transport);
}
