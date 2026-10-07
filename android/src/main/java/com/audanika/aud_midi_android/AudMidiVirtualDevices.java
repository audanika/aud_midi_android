// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import android.content.Context;
import android.content.pm.ServiceInfo;
import android.media.midi.MidiDeviceInfo;
import android.media.midi.MidiReceiver;
import android.os.Build;
import android.os.Bundle;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Connects the virtual MIDI devices of this app, {@link AudMidiDeviceService}
 * and {@link AudMidiUmpDeviceService} subclasses declared in the manifest, with
 * Dart.
 *
 * <p>The system starts such a service when another app opens the device, maybe
 * before any Dart code runs. The receivers of the input ports therefore live
 * here, keyed by the service class, and exist before and after the service.
 */
public final class AudMidiVirtualDevices {
  /** What a running service offers for sending out of its output ports. */
  interface Outputs {
    /** Returns the receiver behind output {@code port}, or null. */
    MidiReceiver outputReceiver(int port);
  }

  private static final class Device {
    final List<AudMidiReceiver> inputs = new ArrayList<>();
    Outputs outputs;
  }

  // The key under which MidiService stores the ServiceInfo of a virtual
  // device; the constant MidiDeviceInfo.PROPERTY_SERVICE_INFO is hidden, its
  // value has not changed since API 23.
  private static final String PROPERTY_SERVICE_INFO = "service_info";

  private static final Map<String, Device> devices = new HashMap<>();

  private AudMidiVirtualDevices() {}

  /**
   * Returns the receiver that collects what other apps send to input
   * {@code port} of the virtual device of {@code service}.
   */
  public static synchronized AudMidiReceiver inputReceiver(String service, int port) {
    return inputs(device(service), port + 1).get(port);
  }

  /**
   * Sends {@code count} bytes of {@code data} from {@code offset} out of output
   * {@code port} of the virtual device of {@code service}, due at
   * {@code timestamp}; returns false when the service does not run because no
   * app has the device open.
   */
  public static boolean send(
      String service, int port, byte[] data, int offset, int count, long timestamp)
      throws IOException {
    MidiReceiver receiver = outputReceiver(service, port);
    if (receiver == null) {
      return false;
    }
    receiver.send(data, offset, count, timestamp);
    return true;
  }

  /** Discards what output {@code port} of {@code service} has not sent yet. */
  public static boolean flush(String service, int port) throws IOException {
    MidiReceiver receiver = outputReceiver(service, port);
    if (receiver == null) {
      return false;
    }
    receiver.flush();
    return true;
  }

  /**
   * Returns the class name of the service behind {@code device} when it is a
   * shim service of this app, or null.
   */
  @SuppressWarnings("deprecation")
  public static String ownService(Context context, MidiDeviceInfo device) {
    Bundle properties = device.getProperties();
    Object value = properties.getParcelable(PROPERTY_SERVICE_INFO);
    if (!(value instanceof ServiceInfo)) {
      return null;
    }
    ServiceInfo info = (ServiceInfo) value;
    if (!context.getPackageName().equals(info.packageName)) {
      return null;
    }
    try {
      Class<?> type = Class.forName(info.name);
      if (AudMidiDeviceService.class.isAssignableFrom(type)) {
        return info.name;
      }
      if (Build.VERSION.SDK_INT >= 33 && AudMidiUmpDeviceService.isServiceClass(type)) {
        return info.name;
      }
    } catch (ClassNotFoundException e) {
      return null;
    }
    return null;
  }

  static synchronized MidiReceiver[] attach(String service, int inputCount, Outputs outputs) {
    Device device = device(service);
    device.outputs = outputs;
    return inputs(device, inputCount).subList(0, inputCount).toArray(new MidiReceiver[0]);
  }

  static synchronized void detach(String service, Outputs outputs) {
    Device device = devices.get(service);
    if (device != null && device.outputs == outputs) {
      device.outputs = null;
    }
  }

  private static synchronized MidiReceiver outputReceiver(String service, int port) {
    Device device = devices.get(service);
    return device == null || device.outputs == null
        ? null
        : device.outputs.outputReceiver(port);
  }

  private static Device device(String service) {
    Device device = devices.get(service);
    if (device == null) {
      device = new Device();
      devices.put(service, device);
    }
    return device;
  }

  private static List<AudMidiReceiver> inputs(Device device, int count) {
    while (device.inputs.size() < count) {
      device.inputs.add(new AudMidiReceiver(AudMidiReceiver.DEFAULT_CAPACITY));
    }
    return device.inputs;
  }
}
