// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.midi.MidiManager;
import android.net.nsd.NsdManager;
import android.net.wifi.WifiManager;

/**
 * Holds the application context and reads what the MIDI backend needs from a
 * context, so that Dart needs no binding of the large {@link Context} class.
 */
public final class AudMidiContext {
  private static volatile Context context;

  private AudMidiContext() {}

  /** Returns the application context captured at startup, or null. */
  public static Context get() {
    return context;
  }

  /** Stores the application context of {@code value}; null is ignored. */
  public static void set(Context value) {
    if (value == null) {
      return;
    }
    Context application = value.getApplicationContext();
    context = application != null ? application : value;
  }

  /** Returns the MIDI manager, or null when the device has no MIDI support. */
  public static MidiManager midiManager(Context context) {
    if (!context.getPackageManager().hasSystemFeature(PackageManager.FEATURE_MIDI)) {
      return null;
    }
    return (MidiManager) context.getSystemService(Context.MIDI_SERVICE);
  }

  /** Returns the Bluetooth manager, or null without Bluetooth LE. */
  public static BluetoothManager bluetoothManager(Context context) {
    if (!context
        .getPackageManager()
        .hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
      return null;
    }
    return (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
  }

  /** Returns the network service discovery manager. */
  public static NsdManager nsdManager(Context context) {
    return (NsdManager) context.getSystemService(Context.NSD_SERVICE);
  }

  /** Returns the Wi-Fi manager of the application context. */
  public static WifiManager wifiManager(Context context) {
    return (WifiManager)
        context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
  }

  /** Returns whether the app holds {@code permission}. */
  public static boolean hasPermission(Context context, String permission) {
    return context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED;
  }

  /** Returns whether the device has the system feature {@code feature}. */
  public static boolean hasFeature(Context context, String feature) {
    return context.getPackageManager().hasSystemFeature(feature);
  }

  /** Returns the package name of the app. */
  public static String packageName(Context context) {
    return context.getPackageName();
  }
}
