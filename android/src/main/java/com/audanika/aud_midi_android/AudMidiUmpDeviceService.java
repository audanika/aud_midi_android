// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import android.annotation.TargetApi;
import android.media.midi.MidiDeviceInfo;
import android.media.midi.MidiReceiver;
import android.media.midi.MidiUmpDeviceService;
import java.util.Arrays;
import java.util.List;

/**
 * A virtual Universal MIDI Packet device (API 33) whose ports belong to the
 * Dart side of the app. Its data are UMP words, big-endian, four bytes each.
 *
 * <p>Declare it, or one subclass per device, in the manifest with the action
 * {@code android.media.midi.MidiUmpDeviceService}.
 */
@TargetApi(33)
public class AudMidiUmpDeviceService extends MidiUmpDeviceService
    implements AudMidiVirtualDevices.Outputs {
  @Override
  public List<MidiReceiver> onGetInputPortReceivers() {
    MidiDeviceInfo info = getDeviceInfo();
    int count = info == null ? 0 : info.getInputPortCount();
    return Arrays.asList(AudMidiVirtualDevices.attach(getClass().getName(), count, this));
  }

  @Override
  public MidiReceiver outputReceiver(int port) {
    List<MidiReceiver> receivers = getOutputPortReceivers();
    return receivers != null && port >= 0 && port < receivers.size()
        ? receivers.get(port)
        : null;
  }

  @Override
  public void onDestroy() {
    AudMidiVirtualDevices.detach(getClass().getName(), this);
    super.onDestroy();
  }

  static boolean isServiceClass(Class<?> type) {
    return AudMidiUmpDeviceService.class.isAssignableFrom(type);
  }
}
