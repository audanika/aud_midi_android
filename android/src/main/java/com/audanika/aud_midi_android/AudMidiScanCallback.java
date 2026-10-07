// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import java.util.List;

/** Forwards the results of a Bluetooth LE scan to an {@link AudMidiScanListener}. */
public final class AudMidiScanCallback extends ScanCallback {
  private final AudMidiScanListener listener;

  /** Creates a callback that forwards to {@code listener}. */
  public AudMidiScanCallback(AudMidiScanListener listener) {
    this.listener = listener;
  }

  @Override
  public void onScanResult(int callbackType, ScanResult result) {
    listener.onScanResult(result);
  }

  @Override
  public void onBatchScanResults(List<ScanResult> results) {
    for (ScanResult result : results) {
      listener.onScanResult(result);
    }
  }

  @Override
  public void onScanFailed(int errorCode) {
    listener.onScanFailed(errorCode);
  }
}
