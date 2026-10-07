// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

// #############################################################################
/// One chunk of MIDI data as Android delivered it to `MidiReceiver.onSend`,
/// with its timestamp in nanoseconds of `CLOCK_MONOTONIC`.
typedef MidiAndroidChunk = ({int timestampNanos, Uint8List bytes});

// #############################################################################
/// What one drain of an `AudMidiReceiver` returned: the chunks and the
/// number of chunks the full buffer dropped since the drain before.
typedef MidiAndroidDrained = ({int dropped, List<MidiAndroidChunk> chunks});

// #############################################################################
/// Reads the data `AudMidiReceiver.drain()` returns.
///
/// Layout, big-endian: the number of dropped chunks as int32, then per
/// chunk the timestamp as int64, the length as int32 and the bytes.
final class MidiAndroidReceiveDecoder {
  /// Creates a decoder.
  const MidiAndroidReceiveDecoder();

  // ...........................................................................
  /// Decodes [data].
  ///
  /// Throws a [FormatException] when [data] ends inside a header or a
  /// chunk.
  MidiAndroidDrained decode(Uint8List data) {
    final view = ByteData.sublistView(data);
    _require(data, 0, headerSize);
    final dropped = view.getInt32(0);
    final chunks = <MidiAndroidChunk>[];
    var offset = headerSize;
    while (offset < data.length) {
      _require(data, offset, chunkHeaderSize);
      final timestamp = view.getInt64(offset);
      final length = view.getInt32(offset + 8);
      final start = offset + chunkHeaderSize;
      _require(data, start, length);
      chunks.add((
        timestampNanos: timestamp,
        bytes: Uint8List.sublistView(data, start, start + length),
      ));
      offset = start + length;
    }
    return (dropped: dropped, chunks: chunks);
  }

  // ...........................................................................
  /// The size of the header in front of the chunks: the dropped count.
  static const int headerSize = 4;

  /// The size of the header in front of each chunk: timestamp and length.
  static const int chunkHeaderSize = 12;

  // ...........................................................................
  static void _require(Uint8List data, int offset, int length) {
    if (length < 0 || offset + length > data.length) {
      throw FormatException('Truncated receive data', data, offset);
    }
  }
}
