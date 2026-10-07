// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'package:aud_midi_standard/aud_midi_standard.dart';

// #############################################################################
/// Turns packets into the byte chunks an Android MIDI port takes.
///
/// MIDI 1.0 bytes stay as they are, UMP words become big-endian bytes. No
/// chunk exceeds [maxChunk] bytes, and a UMP chunk never splits a packet:
/// Android itself would cut at 1015 bytes, inside a word.
final class MidiAndroidPacketEncoder {
  /// Creates an encoder for chunks of at most [maxChunk] bytes, at least
  /// one largest packet of 16 bytes.
  const MidiAndroidPacketEncoder({this.maxChunk = defaultMaxChunk})
    : assert(maxChunk >= 16);

  // ...........................................................................
  /// Returns the chunks of [packet]; none for an empty packet.
  ///
  /// Throws an [ArgumentError] when the last UMP of [packet] is incomplete.
  List<Uint8List> encode(MidiPacket packet) => switch (packet) {
    MidiBytesPacket(:final bytes) => _split(bytes.bytes),
    MidiUmpPacket(:final words) => _splitUmps(words),
  };

  // ...........................................................................
  /// The largest chunk in bytes.
  final int maxChunk;

  // ...........................................................................
  /// The default for [maxChunk]: the largest multiple of four below the
  /// 1015 bytes of payload an Android MIDI packet holds.
  static const int defaultMaxChunk = 1012;

  /// Returns [words] as big-endian bytes.
  static Uint8List pack(List<int> words) {
    final data = ByteData(words.length * 4);
    for (var i = 0; i < words.length; i++) {
      data.setUint32(i * 4, words[i] & 0xffffffff);
    }
    return data.buffer.asUint8List();
  }

  // ...........................................................................
  List<Uint8List> _split(Uint8List bytes) => [
    for (var start = 0; start < bytes.length; start += maxChunk)
      Uint8List.fromList(
        bytes.sublist(start, (start + maxChunk).clamp(0, bytes.length)),
      ),
  ];

  List<Uint8List> _splitUmps(Uint32List words) {
    final chunks = <Uint8List>[];
    var chunkStart = 0;
    var index = 0;
    while (index < words.length) {
      final size = Ump.sizeOf(words[index]);
      if (index + size > words.length) {
        throw ArgumentError.value(words, 'packet', 'Incomplete last UMP');
      }
      if ((index + size - chunkStart) * 4 > maxChunk) {
        chunks.add(pack(words.sublist(chunkStart, index)));
        chunkStart = index;
      }
      index += size;
    }
    if (index > chunkStart) chunks.add(pack(words.sublist(chunkStart, index)));
    return chunks;
  }
}
