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
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * A virtual Universal MIDI Packet device (API 33) for tests that sends
 * everything it receives on port n unchanged, timestamp included, back out of
 * port n.
 *
 * <p>Only test apps declare it in their manifest.
 */
@TargetApi(33)
public final class AudMidiUmpLoopbackService extends MidiUmpDeviceService {
  @Override
  public List<MidiReceiver> onGetInputPortReceivers() {
    MidiDeviceInfo info = getDeviceInfo();
    int count = info == null ? 0 : info.getInputPortCount();
    List<MidiReceiver> receivers = new ArrayList<>();
    for (int i = 0; i < count; i++) {
      receivers.add(new Loop(i));
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
      List<MidiReceiver> outputs = getOutputPortReceivers();
      return outputs != null && port < outputs.size() ? outputs.get(port) : null;
    }
  }
}
