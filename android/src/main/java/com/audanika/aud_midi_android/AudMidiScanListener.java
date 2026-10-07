// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import android.bluetooth.le.ScanResult;

/**
 * Learns the results of a Bluetooth LE scan. Dart implements it as a listener
 * behind {@link AudMidiScanCallback}.
 */
public interface AudMidiScanListener {
  /** Called for every advertisement found. */
  void onScanResult(ScanResult result);

  /** Called when the scan could not start, with the {@code ScanCallback} error. */
  void onScanFailed(int errorCode);
}
