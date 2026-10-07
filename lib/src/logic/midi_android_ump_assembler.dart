// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'package:aud_midi_standard/aud_midi_standard.dart';

// #############################################################################
/// Turns the bytes of a UMP port into complete Universal MIDI Packets.
///
/// Android carries UMP words as big-endian bytes, four per word. A chunk
/// may end inside a word or a packet; the rest waits for the next chunk.
final class MidiAndroidUmpAssembler {
  /// Creates an assembler without a rest.
  MidiAndroidUmpAssembler();

  // ...........................................................................
  /// Adds [bytes] and returns the words of all packets they complete.
  Uint32List add(Uint8List bytes) {
    final data = Uint8List(_rest.length + bytes.length)
      ..setAll(0, _rest)
      ..setAll(_rest.length, bytes);
    final view = ByteData.sublistView(data);
    final wordCount = data.length ~/ 4;
    var complete = 0;
    while (complete < wordCount) {
      final size = Ump.sizeOf(view.getUint32(complete * 4));
      if (complete + size > wordCount) break;
      complete += size;
    }
    _rest = Uint8List.fromList(data.sublist(complete * 4));
    return Uint32List.fromList([
      for (var i = 0; i < complete; i++) view.getUint32(i * 4),
    ]);
  }

  /// Drops the rest of an incomplete packet.
  void reset() => _rest = Uint8List(0);

  // ...........................................................................
  /// The number of bytes of an incomplete packet that wait for the next
  /// chunk.
  int get pending => _rest.length;

  // ...........................................................................
  Uint8List _rest = Uint8List(0);
}
