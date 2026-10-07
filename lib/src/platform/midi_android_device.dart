// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'midi_android_device_description.dart';
import 'midi_android_receiver.dart';
import 'midi_android_sender.dart';

// #############################################################################
/// An Android MIDI device the platform opened, a `MidiDevice`.
abstract interface class MidiAndroidDevice {
  // ...........................................................................
  /// Opens the Android output [port], data out of the device, and returns
  /// its receiver, or null when the port is missing or busy.
  ///
  /// - [onData] runs in this isolate whenever data wait in the receiver.
  MidiAndroidReceiver? openOutputPort({
    required int port,
    required void Function() onData,
  });

  /// Opens the Android input [port], data into the device, through AMidi
  /// (API 29), or returns null when AMidi cannot open it.
  MidiAndroidSender? openNativeInputPort(int port);

  /// Opens the Android input [port] through `MidiInputPort`, or returns
  /// null when the port is missing or busy.
  MidiAndroidSender? openJavaInputPort(int port);

  /// Closes the device with all ports still open.
  void close();

  // ...........................................................................
  /// The description of the device.
  MidiAndroidDeviceDescription get description;
}
