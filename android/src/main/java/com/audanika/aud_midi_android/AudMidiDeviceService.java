// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import android.media.midi.MidiDeviceInfo;
import android.media.midi.MidiDeviceService;
import android.media.midi.MidiReceiver;

/**
 * A virtual MIDI 1.0 device whose ports belong to the Dart side of the app.
 *
 * <p>Declare it, or one subclass per device, in the manifest with a
 * {@code midi_device_info} resource. What other apps send to its input ports
 * arrives at the app's virtual input ports; what the app sends to its virtual
 * output ports leaves through the device's output ports.
 */
public class AudMidiDeviceService extends MidiDeviceService
    implements AudMidiVirtualDevices.Outputs {
  @Override
  public MidiReceiver[] onGetInputPortReceivers() {
    MidiDeviceInfo info = getDeviceInfo();
    int count = info == null ? 0 : info.getInputPortCount();
    return AudMidiVirtualDevices.attach(getClass().getName(), count, this);
  }

  @Override
  public MidiReceiver outputReceiver(int port) {
    MidiReceiver[] receivers = getOutputPortReceivers();
    return receivers != null && port >= 0 && port < receivers.length
        ? receivers[port]
        : null;
  }

  @Override
  public void onDestroy() {
    AudMidiVirtualDevices.detach(getClass().getName(), this);
    super.onDestroy();
  }
}
