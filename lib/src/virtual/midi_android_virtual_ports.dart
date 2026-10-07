// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';

// #############################################################################
/// The virtual ports of an Android app: static, declared in the manifest.
///
/// Android creates no virtual port at runtime. An app declares an
/// `AudMidiDeviceService` (or `AudMidiUmpDeviceService`, API 33) with its
/// ports in a `midi_device_info` resource; other apps see it as a MIDI
/// device, and the backend lists its ports with `isOwn` set. [create] hands
/// out such a declared port; the spec only chooses which one.
final class MidiAndroidVirtualPorts implements MidiVirtualPortsBackend {
  /// Creates the virtual port support over the backend's [ports]; [closePort]
  /// closes a port that is removed.
  MidiAndroidVirtualPorts({required this._ports, required this._closePort});

  // ...........................................................................
  /// Returns a declared own port with the direction of [spec]: the one named
  /// like the spec, else the first one not handed out yet.
  ///
  /// Throws [MidiUnsupported] when no such port is left, because Android
  /// cannot create one at runtime.
  @override
  Future<MidiPortInfo> create(MidiVirtualPortSpec spec) async {
    final free = [
      for (final port in _ports())
        if (port.isOwn &&
            port.direction == spec.direction &&
            !_claimed.contains(port.id))
          port,
    ];
    final match =
        free.where((port) => port.name == spec.name).firstOrNull ??
        free.firstOrNull;
    if (match == null) {
      throw MidiUnsupported(
        'creating a virtual ${spec.direction.name} port at runtime; declare '
        'it with an AudMidiDeviceService in the manifest',
      );
    }
    _claimed.add(match.id);
    return match;
  }

  /// Gives back the port [port] that [create] handed out and closes it.
  ///
  /// Throws [MidiPortGone] when [create] did not hand it out.
  @override
  Future<void> remove(MidiPortId port) async {
    if (!_claimed.remove(port)) throw MidiPortGone(port);
    await _closePort(port);
  }

  // ...........................................................................
  /// The ids of the ports [create] handed out.
  Set<MidiPortId> get claimed => {..._claimed};

  // ...........................................................................
  final List<MidiPortInfo> Function() _ports;
  final Future<void> Function(MidiPortId port) _closePort;
  final Set<MidiPortId> _claimed = {};
}
