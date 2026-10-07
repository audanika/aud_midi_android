// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import android.media.midi.MidiReceiver;

/**
 * Collects the MIDI data of one port for Dart.
 *
 * <p>The MIDI thread copies every chunk with its timestamp into a bounded
 * buffer and signals the {@link AudMidiDataListener} once; Dart then takes
 * everything with {@link #drain()}. When the buffer is full, the newest chunk
 * is dropped and counted. Data that arrives while no listener is set is
 * discarded.
 */
public final class AudMidiReceiver extends MidiReceiver {
  /** The default buffer size in bytes. */
  public static final int DEFAULT_CAPACITY = 64 * 1024;

  /** The size of the header in front of every chunk: timestamp and length. */
  public static final int RECORD_HEADER_SIZE = 12;

  private final Object lock = new Object();
  private final byte[] buffer;
  private int size;
  private int dropped;
  private boolean signalPending;
  private AudMidiDataListener listener;
  private int token;

  /** Creates a receiver with a buffer of {@code capacity} bytes. */
  public AudMidiReceiver(int capacity) {
    this.buffer = new byte[Math.max(capacity, RECORD_HEADER_SIZE + 1)];
  }

  /**
   * Delivers to {@code value}, which learns about new data with {@code token};
   * null stops the delivery. Both discard the data buffered so far.
   */
  public void setListener(AudMidiDataListener value, int token) {
    synchronized (lock) {
      this.listener = value;
      this.token = token;
      signalPending = false;
      size = 0;
      dropped = 0;
    }
  }

  @Override
  public void onSend(byte[] msg, int offset, int count, long timestamp) {
    if (count <= 0) {
      return;
    }
    long time = timestamp != 0 ? timestamp : System.nanoTime();
    AudMidiDataListener toSignal = null;
    int signalToken = 0;
    synchronized (lock) {
      if (listener == null) {
        return;
      }
      if (size + RECORD_HEADER_SIZE + count > buffer.length) {
        dropped++;
      } else {
        putLong(buffer, size, time);
        putInt(buffer, size + 8, count);
        System.arraycopy(msg, offset, buffer, size + RECORD_HEADER_SIZE, count);
        size += RECORD_HEADER_SIZE + count;
      }
      if (!signalPending) {
        signalPending = true;
        toSignal = listener;
        signalToken = token;
      }
    }
    if (toSignal != null) {
      toSignal.onDataAvailable(signalToken);
    }
  }

  /**
   * Returns and removes everything received since the last call, or null when
   * nothing arrived.
   *
   * <p>Layout, big-endian: the number of dropped chunks as int32, then per chunk
   * the timestamp in nanoseconds of {@code System.nanoTime()} as int64, the
   * length as int32 and the bytes.
   */
  public byte[] drain() {
    synchronized (lock) {
      signalPending = false;
      if (size == 0 && dropped == 0) {
        return null;
      }
      byte[] result = new byte[4 + size];
      putInt(result, 0, dropped);
      System.arraycopy(buffer, 0, result, 4, size);
      size = 0;
      dropped = 0;
      return result;
    }
  }

  private static void putInt(byte[] target, int index, int value) {
    target[index] = (byte) (value >>> 24);
    target[index + 1] = (byte) (value >>> 16);
    target[index + 2] = (byte) (value >>> 8);
    target[index + 3] = (byte) value;
  }

  private static void putLong(byte[] target, int index, long value) {
    putInt(target, index, (int) (value >>> 32));
    putInt(target, index + 4, (int) value);
  }
}
