// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import android.media.midi.MidiDeviceInfo;
import android.media.midi.MidiDeviceService;
import android.media.midi.MidiReceiver;
import java.io.IOException;

/**
 * A virtual MIDI device for tests that sends everything it receives on input
 * port n unchanged, timestamp included, out of output port n.
 *
 * <p>Only test apps declare it in their manifest.
 */
public final class AudMidiLoopbackService extends MidiDeviceService {
  @Override
  public MidiReceiver[] onGetInputPortReceivers() {
    MidiDeviceInfo info = getDeviceInfo();
    int count = info == null ? 0 : info.getInputPortCount();
    MidiReceiver[] receivers = new MidiReceiver[count];
    for (int i = 0; i < count; i++) {
      receivers[i] = new Loop(i);
    }
    return receivers;
  }

  private final class Loop extends MidiReceiver {
    private final int port;

    Loop(int port) {
      this.port = port;
    }

    @Override
    public void onSend(byte[] msg, int offset, int count, long timestamp)
        throws IOException {
      MidiReceiver output = output();
      if (output != null) {
        output.send(msg, offset, count, timestamp);
      }
    }

    @Override
    public void onFlush() throws IOException {
      MidiReceiver output = output();
      if (output != null) {
        output.flush();
      }
    }

    private MidiReceiver output() {
      MidiReceiver[] outputs = getOutputPortReceivers();
      return outputs != null && port < outputs.length ? outputs[port] : null;
    }
  }
}
