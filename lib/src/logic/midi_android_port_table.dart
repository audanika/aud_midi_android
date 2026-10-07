// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_standard/aud_midi_standard.dart';

import '../platform/midi_android_device_description.dart';
import 'midi_android_port_mapper.dart';

// #############################################################################
/// Keeps the known Android devices with their ports and turns every change
/// into port events.
final class MidiAndroidPortTable {
  /// Creates an empty table that maps devices with [mapper].
  MidiAndroidPortTable({this.mapper = const MidiAndroidPortMapper()});

  // ...........................................................................
  /// Replaces all devices by [devices] and returns the events of the
  /// change.
  List<MidiPortEvent> sync(List<MidiAndroidDeviceDescription> devices) {
    final before = _portsById();
    _devices
      ..clear()
      ..addEntries(devices.map((device) => MapEntry(device.id, device)));
    return _diff(before, _portsById());
  }

  /// Adds [device] or replaces the device with the same id and returns the
  /// events of the change.
  List<MidiPortEvent> add(MidiAndroidDeviceDescription device) {
    final before = _portsById();
    _devices[device.id] = device;
    return _diff(before, _portsById());
  }

  /// Removes the device [id] and returns the events of the change.
  List<MidiPortEvent> remove(int id) {
    final before = _portsById();
    _devices.remove(id);
    return _diff(before, _portsById());
  }

  // ...........................................................................
  /// Returns the port [id], or null when no known device has it.
  MidiPortInfo? port(MidiPortId id) => _portsById()[id];

  /// Returns the device that has the port [id], or null.
  MidiAndroidDeviceDescription? deviceOf(MidiPortId id) {
    for (final device in _devices.values) {
      if (mapper.ports(device).any((port) => port.id == id)) return device;
    }
    return null;
  }

  /// Returns the device [id], or null.
  MidiAndroidDeviceDescription? device(int id) => _devices[id];

  /// Returns the ports of the device [id]; empty when it is unknown.
  List<MidiPortInfo> portsOf(int id) {
    final device = _devices[id];
    return device == null ? const [] : mapper.ports(device);
  }

  // ...........................................................................
  /// Maps the descriptions to models.
  final MidiAndroidPortMapper mapper;

  /// The ports of all known devices.
  List<MidiPortInfo> get ports => [
    for (final device in _devices.values) ...mapper.ports(device),
  ];

  /// The known devices.
  List<MidiAndroidDeviceDescription> get devices => [..._devices.values];

  // ...........................................................................
  final Map<int, MidiAndroidDeviceDescription> _devices = {};

  Map<MidiPortId, MidiPortInfo> _portsById() => {
    for (final port in ports) port.id: port,
  };

  static List<MidiPortEvent> _diff(
    Map<MidiPortId, MidiPortInfo> before,
    Map<MidiPortId, MidiPortInfo> after,
  ) => [
    for (final port in before.values)
      if (!after.containsKey(port.id)) MidiPortRemoved(port: port),
    for (final port in after.values)
      if (before[port.id] case final previous?)
        if (previous != port) MidiPortChanged(port: port, previous: previous),
    for (final port in after.values)
      if (!before.containsKey(port.id)) MidiPortAdded(port: port),
  ];
}
