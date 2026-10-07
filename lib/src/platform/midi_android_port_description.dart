// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
/// One port of an Android MIDI device as `MidiDeviceInfo.PortInfo` describes
/// it.
///
/// Android names the ports from the device's point of view: an input port
/// takes data into the device, an output port delivers data out of it.
final class MidiAndroidPortDescription {
  /// Creates the description of port [number] of [type] named [name].
  const MidiAndroidPortDescription({
    required this.type,
    required this.number,
    this.name = '',
  });

  // ...........................................................................
  /// The type of the port, [typeInput] or [typeOutput].
  final int type;

  /// The number of the port among the ports of its type, from 0.
  final int number;

  /// The name of the port, empty when the device gives none.
  final String name;

  /// Whether the port takes data into the device.
  bool get isInput => type == typeInput;

  // ...........................................................................
  /// `PortInfo.TYPE_INPUT`: the port takes data into the device.
  static const int typeInput = 1;

  /// `PortInfo.TYPE_OUTPUT`: the port delivers data out of the device.
  static const int typeOutput = 2;

  // ...........................................................................
  @override
  String toString() =>
      "MidiAndroidPortDescription(type: $type, number: $number, name: '$name')";
}
