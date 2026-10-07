// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';

import '../platform/midi_android_device_description.dart';
import '../platform/midi_android_port_description.dart';

// #############################################################################
/// Turns Android device descriptions into the device and port models of the
/// package.
///
/// Android names ports from the device's point of view, the package from the
/// app's: the Android input port of a device is an output of the app and
/// vice versa. The app's own virtual devices are seen from inside, so their
/// Android input ports are inputs of the app.
final class MidiAndroidPortMapper {
  /// Creates a mapper whose ids start with [backend].
  const MidiAndroidPortMapper({this.backend = 'android'});

  // ...........................................................................
  /// Returns the ports of [device] seen from the app.
  List<MidiPortInfo> ports(MidiAndroidDeviceDescription device) => [
    for (final port in device.ports) _port(device, port),
  ];

  /// Returns the device model of [device].
  MidiDeviceInfo device(MidiAndroidDeviceDescription device) => MidiDeviceInfo(
    id: deviceId(device),
    name: deviceName(device),
    manufacturer: device.manufacturer,
    product: device.product,
    serialNumber: device.serialNumber,
    transport: transport(device),
    driver: driver(device),
    ports: [for (final port in ports(device)) port.id],
    native: _native(device),
  );

  // ...........................................................................
  /// Returns the id of [device].
  MidiDeviceId deviceId(MidiAndroidDeviceDescription device) =>
      MidiDeviceId.of(backend: backend, nativeId: '${device.id}');

  /// Returns the id of the Android [port] of [device].
  ///
  /// Ports of the app's own virtual devices use the service class, which
  /// stays the same across sessions.
  MidiPortId portId(
    MidiAndroidDeviceDescription device,
    MidiAndroidPortDescription port,
  ) {
    final direction = this.direction(device, port) == MidiDirection.input
        ? 'in'
        : 'out';
    final owner = device.ownService;
    final nativeId = owner == null
        ? '${device.id}:$direction:${port.number}'
        : 'own:$owner:$direction:${port.number}';
    return MidiPortId.of(backend: backend, nativeId: nativeId);
  }

  /// Returns the direction of the Android [port] of [device] seen from the
  /// app.
  MidiDirection direction(
    MidiAndroidDeviceDescription device,
    MidiAndroidPortDescription port,
  ) {
    final intoTheApp = device.ownService == null ? !port.isInput : port.isInput;
    return intoTheApp ? MidiDirection.input : MidiDirection.output;
  }

  /// Returns the name of [device]: its name, else its product, else a name
  /// made of its id.
  String deviceName(MidiAndroidDeviceDescription device) {
    if (device.name.isNotEmpty) return device.name;
    if (device.product.isNotEmpty) return device.product;
    return 'MIDI device ${device.id}';
  }

  /// Returns the driver or owner of [device]: the service class of an own
  /// virtual device, `android.media.midi` for all others.
  String driver(MidiAndroidDeviceDescription device) =>
      device.ownService ?? 'android.media.midi';

  /// Returns how [device] is attached.
  MidiTransport transport(MidiAndroidDeviceDescription device) =>
      switch (device.type) {
        MidiAndroidDeviceDescription.typeUsb => MidiTransport.usb,
        MidiAndroidDeviceDescription.typeVirtual => MidiTransport.virtual,
        MidiAndroidDeviceDescription.typeBluetooth => MidiTransport.bluetoothLe,
        _ => MidiTransport.unknown,
      };

  /// Returns the protocol of [device]: MIDI 1.0 for byte-stream devices and
  /// UMP devices with a MIDI 1.0 default protocol, MIDI 2.0 for the other
  /// UMP devices.
  MidiProtocol protocol(MidiAndroidDeviceDescription device) {
    if (!device.isUmp) return MidiProtocol.midi1;
    return _midi1Protocols.contains(device.defaultProtocol)
        ? MidiProtocol.midi1
        : MidiProtocol.midi2;
  }

  /// Returns the capabilities of a port of [device] with [direction].
  ///
  /// Inputs carry the receive time of Android. Outputs to USB and Bluetooth
  /// devices accept future timestamps: the MIDI service holds the data in
  /// its scheduler until they are due and discards them on a flush. A
  /// virtual device gets the timestamp with the data and decides itself,
  /// so its outputs are scheduled by the engine.
  MidiPortCapabilities capabilities(
    MidiAndroidDeviceDescription device,
    MidiDirection direction,
  ) {
    final scheduled =
        direction == MidiDirection.output &&
        device.ownService == null &&
        (device.type == MidiAndroidDeviceDescription.typeUsb ||
            device.type == MidiAndroidDeviceDescription.typeBluetooth);
    return MidiPortCapabilities(
      timestampsIn: direction == MidiDirection.input,
      scheduledSend: scheduled,
      cancelPending: scheduled,
      ump: device.isUmp,
      sysEx8: device.isUmp && !_upTo64Bits.contains(device.defaultProtocol),
    );
  }

  // ...........................................................................
  /// The prefix of all ids, the name of the backend.
  final String backend;

  // ...........................................................................
  static const _midi1Protocols = {
    MidiAndroidDeviceDescription.protocolMidi1UpTo64Bits,
    MidiAndroidDeviceDescription.protocolMidi1UpTo64BitsAndJrts,
    MidiAndroidDeviceDescription.protocolMidi1UpTo128Bits,
    MidiAndroidDeviceDescription.protocolMidi1UpTo128BitsAndJrts,
  };

  static const _upTo64Bits = {
    MidiAndroidDeviceDescription.protocolMidi1UpTo64Bits,
    MidiAndroidDeviceDescription.protocolMidi1UpTo64BitsAndJrts,
  };

  MidiPortInfo _port(
    MidiAndroidDeviceDescription device,
    MidiAndroidPortDescription port,
  ) {
    final direction = this.direction(device, port);
    return MidiPortInfo(
      id: portId(device, port),
      deviceId: deviceId(device),
      name: _portName(device, port),
      manufacturer: device.manufacturer,
      direction: direction,
      index: port.number,
      transport: transport(device),
      protocol: protocol(device),
      isVirtual: device.type == MidiAndroidDeviceDescription.typeVirtual,
      isOwn: device.ownService != null,
      capabilities: capabilities(device, direction),
      serialNumber: device.serialNumber,
      native: {
        ..._native(device),
        'androidPortType': port.type,
        'androidPortNumber': port.number,
        // The engine derives the device of the port from these.
        MidiPortRegistry.deviceNameKey: deviceName(device),
        MidiPortRegistry.productKey: device.product,
        MidiPortRegistry.driverKey: driver(device),
      },
    );
  }

  String _portName(
    MidiAndroidDeviceDescription device,
    MidiAndroidPortDescription port,
  ) {
    if (port.name.isNotEmpty) return port.name;
    final siblings = device.ports.where((p) => p.type == port.type).length;
    final name = deviceName(device);
    return siblings > 1 ? '$name ${port.number + 1}' : name;
  }

  Map<String, Object?> _native(MidiAndroidDeviceDescription device) => {
    'androidDeviceId': device.id,
    'androidType': device.type,
    'androidTransport': device.transport,
    'androidDefaultProtocol': device.defaultProtocol,
    'androidVersion': device.version,
    'androidPrivate': device.isPrivate,
    if (device.ownService != null) 'androidService': device.ownService,
    if (device.bluetoothAddress.isNotEmpty)
      'bluetoothAddress': device.bluetoothAddress,
  };
}
