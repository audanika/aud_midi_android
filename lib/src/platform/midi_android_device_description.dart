// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'midi_android_port_description.dart';

// #############################################################################
/// An Android MIDI device as `MidiDeviceInfo` describes it, read once into
/// plain Dart.
final class MidiAndroidDeviceDescription {
  /// Creates the description of the device [id].
  ///
  /// - [type] how the device is attached, [typeUsb], [typeVirtual] or
  ///   [typeBluetooth].
  /// - [transport] [transportByteStream] for MIDI 1.0 bytes,
  ///   [transportUmp] for Universal MIDI Packets (API 33).
  /// - [defaultProtocol] `MidiDeviceInfo.getDefaultProtocol()` (API 33),
  ///   [protocolUnknown] otherwise.
  /// - [ownService] the class name of the shim service behind the device
  ///   when it is a virtual device of this app, null otherwise.
  /// - [bluetoothAddress] the address of a Bluetooth LE device, empty
  ///   otherwise.
  const MidiAndroidDeviceDescription({
    required this.id,
    required this.type,
    this.transport = transportByteStream,
    this.defaultProtocol = protocolUnknown,
    this.name = '',
    this.manufacturer = '',
    this.product = '',
    this.serialNumber = '',
    this.version = '',
    this.ports = const [],
    this.ownService,
    this.bluetoothAddress = '',
    this.isPrivate = false,
  });

  // ...........................................................................
  /// The id the MIDI service assigned; it changes when the device is
  /// plugged in again.
  final int id;

  /// How the device is attached: [typeUsb], [typeVirtual] or
  /// [typeBluetooth].
  final int type;

  /// [transportByteStream] or [transportUmp].
  final int transport;

  /// The default protocol of a UMP device, see the `protocol…` constants.
  final int defaultProtocol;

  /// The property `name`, empty when missing.
  final String name;

  /// The property `manufacturer`, empty when missing.
  final String manufacturer;

  /// The property `product`, empty when missing.
  final String product;

  /// The property `serial_number`, empty when missing.
  final String serialNumber;

  /// The property `version`, empty when missing.
  final String version;

  /// The ports of the device.
  final List<MidiAndroidPortDescription> ports;

  /// The class name of the shim service behind a virtual device of this
  /// app, or null.
  final String? ownService;

  /// The address of a Bluetooth LE device, empty for other devices.
  final String bluetoothAddress;

  /// Whether the device is private to the app that created it.
  final bool isPrivate;

  /// Whether the device exchanges Universal MIDI Packets.
  bool get isUmp => transport == transportUmp;

  // ...........................................................................
  /// `MidiDeviceInfo.TYPE_USB`.
  static const int typeUsb = 1;

  /// `MidiDeviceInfo.TYPE_VIRTUAL`.
  static const int typeVirtual = 2;

  /// `MidiDeviceInfo.TYPE_BLUETOOTH`.
  static const int typeBluetooth = 3;

  /// `MidiManager.TRANSPORT_MIDI_BYTE_STREAM`.
  static const int transportByteStream = 1;

  /// `MidiManager.TRANSPORT_UNIVERSAL_MIDI_PACKETS` (API 33).
  static const int transportUmp = 2;

  /// `MidiDeviceInfo.PROTOCOL_UNKNOWN`.
  static const int protocolUnknown = -1;

  /// `MidiDeviceInfo.PROTOCOL_UMP_USE_MIDI_CI`.
  static const int protocolUseMidiCi = 0;

  /// `MidiDeviceInfo.PROTOCOL_UMP_MIDI_1_0_UP_TO_64_BITS`.
  static const int protocolMidi1UpTo64Bits = 1;

  /// `MidiDeviceInfo.PROTOCOL_UMP_MIDI_1_0_UP_TO_64_BITS_AND_JRTS`.
  static const int protocolMidi1UpTo64BitsAndJrts = 2;

  /// `MidiDeviceInfo.PROTOCOL_UMP_MIDI_1_0_UP_TO_128_BITS`.
  static const int protocolMidi1UpTo128Bits = 3;

  /// `MidiDeviceInfo.PROTOCOL_UMP_MIDI_1_0_UP_TO_128_BITS_AND_JRTS`.
  static const int protocolMidi1UpTo128BitsAndJrts = 4;

  /// `MidiDeviceInfo.PROTOCOL_UMP_MIDI_2_0`.
  static const int protocolMidi2 = 17;

  /// `MidiDeviceInfo.PROTOCOL_UMP_MIDI_2_0_AND_JRTS`.
  static const int protocolMidi2AndJrts = 18;

  // ...........................................................................
  @override
  String toString() =>
      'MidiAndroidDeviceDescription(id: $id, type: $type, '
      'transport: $transport, defaultProtocol: $defaultProtocol, '
      "name: '$name', manufacturer: '$manufacturer', product: '$product', "
      "serialNumber: '$serialNumber', version: '$version', ports: $ports, "
      "ownService: $ownService, bluetoothAddress: '$bluetoothAddress', "
      'isPrivate: $isPrivate)';
}
