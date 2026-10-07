// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// coverage:ignore-file
// Reason: FFI glue to libamidi.so and the JavaVM, which exist on Android
// only. The decision between AMidi and Java is tested in
// android_midi_backend_test.dart.

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:ffi/ffi.dart';
import 'package:jni/jni.dart';

import '../platform/midi_android_sender.dart';
import 'midi_android_amidi_bindings.g.dart';

// #############################################################################
/// The NDK AMidi API, `libamidi.so`, loaded at runtime from API 29.
///
/// AMidi sends without a JNI call per message: the data go straight from
/// native memory into the socket of the MIDI service.
final class MidiAndroidAMidi {
  MidiAndroidAMidi._(this._bindings, this._javaVm);

  // ...........................................................................
  /// Loads AMidi, or returns null below API [minSdk], outside Android or
  /// when a library cannot be loaded.
  static MidiAndroidAMidi? load({required int sdkInt}) {
    if (!Platform.isAndroid || sdkInt < minSdk) return null;
    try {
      final amidi = DynamicLibrary.open('libamidi.so');
      final jni = DynamicLibrary.open('libdartjni.so');
      final getJavaVm = jni
          .lookupFunction<
            Pointer<Pointer<_JniInvokeInterface>> Function(),
            Pointer<Pointer<_JniInvokeInterface>> Function()
          >('GetJavaVM');
      return MidiAndroidAMidi._(MidiAndroidAMidiBindings(amidi), getJavaVm());
    } on ArgumentError {
      return null;
    }
  }

  // ...........................................................................
  /// Connects AMidi to the opened Java `MidiDevice` [device]; returns the
  /// native device, or null when AMidi refuses it.
  Pointer<AMidiDevice>? connect(JObject device) {
    final env = _currentEnv();
    if (env == nullptr) return null;
    final out = calloc<Pointer<AMidiDevice>>();
    try {
      final status = _bindings.AMidiDevice_fromJava(
        env.cast(),
        // AMidi needs the raw jobject, which package:jni only exposes
        // through its internal reference, as the generated bindings do.
        // ignore: invalid_use_of_internal_member
        device.reference.pointer,
        out,
      );
      return status == 0 && out.value != nullptr ? out.value : null;
    } finally {
      calloc.free(out);
    }
  }

  /// Opens the Android input [port] of [device] for sending, or returns
  /// null when AMidi cannot open it.
  MidiAndroidSender? openInputPort(Pointer<AMidiDevice> device, int port) {
    final out = calloc<Pointer<AMidiInputPort>>();
    try {
      final status = _bindings.AMidiInputPort_open(device, port, out);
      if (status != 0 || out.value == nullptr) return null;
      return _MidiAndroidAMidiSender(_bindings, out.value);
    } finally {
      calloc.free(out);
    }
  }

  /// Disconnects AMidi from the Java device; close its ports before.
  void release(Pointer<AMidiDevice> device) =>
      _bindings.AMidiDevice_release(device);

  // ...........................................................................
  /// The API level that introduced AMidi.
  static const int minSdk = 29;

  // ...........................................................................
  final MidiAndroidAMidiBindings _bindings;
  final Pointer<Pointer<_JniInvokeInterface>> _javaVm;

  static const _jniVersion16 = 0x00010006;

  /// Returns the JNIEnv of the current thread, or nullptr.
  ///
  /// package:jni attaches the thread on its first JNI call and detaches it
  /// when the thread ends, so a JNI call right before suffices.
  Pointer<Void> _currentEnv() {
    if (_javaVm == nullptr) return nullptr;
    'aud_midi'.toJString().release();
    final env = calloc<Pointer<Void>>();
    try {
      final getEnv = _javaVm.value.ref.getEnv
          .asFunction<
            int Function(
              Pointer<Pointer<_JniInvokeInterface>>,
              Pointer<Pointer<Void>>,
              int,
            )
          >();
      return getEnv(_javaVm, env, _jniVersion16) == 0 ? env.value : nullptr;
    } finally {
      calloc.free(env);
    }
  }
}

// #############################################################################
/// Sends through an AMidi input port with `AMidiInputPort_sendWithTimestamp`.
final class _MidiAndroidAMidiSender implements MidiAndroidSender {
  _MidiAndroidAMidiSender(this._bindings, this._port);

  final MidiAndroidAMidiBindings _bindings;
  final Pointer<AMidiInputPort> _port;
  Pointer<Uint8> _buffer = nullptr;
  int _capacity = 0;
  bool _closed = false;

  @override
  void send(Uint8List data, {required int timestampNanos}) {
    if (data.isEmpty) return;
    final buffer = _bufferFor(data.length);
    buffer.asTypedList(data.length).setAll(0, data);
    final sent = _bindings.AMidiInputPort_sendWithTimestamp(
      _port,
      buffer,
      data.length,
      timestampNanos,
    );
    if (sent != data.length) {
      throw MidiNativeError(
        api: 'AMidiInputPort_sendWithTimestamp',
        code: sent < 0 ? sent : -1,
      );
    }
  }

  @override
  void flush() {
    final status = _bindings.AMidiInputPort_sendFlush(_port);
    if (status != 0) {
      throw MidiNativeError(api: 'AMidiInputPort_sendFlush', code: status);
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _bindings.AMidiInputPort_close(_port);
    if (_buffer != nullptr) malloc.free(_buffer);
    _buffer = nullptr;
  }

  @override
  String get kind => MidiAndroidSender.amidi;

  Pointer<Uint8> _bufferFor(int length) {
    if (length <= _capacity) return _buffer;
    if (_buffer != nullptr) malloc.free(_buffer);
    _capacity = length < 1024 ? 1024 : length;
    return _buffer = malloc<Uint8>(_capacity);
  }
}

// #############################################################################
/// The function table of a `JavaVM`, `struct JNIInvokeInterface` of jni.h.
final class _JniInvokeInterface extends Struct {
  external Pointer<Void> reserved0;
  external Pointer<Void> reserved1;
  external Pointer<Void> reserved2;
  external Pointer<Void> destroyJavaVm;
  external Pointer<Void> attachCurrentThread;
  external Pointer<Void> detachCurrentThread;
  external Pointer<
    NativeFunction<
      Int32 Function(
        Pointer<Pointer<_JniInvokeInterface>>,
        Pointer<Pointer<Void>>,
        Int32,
      )
    >
  >
  getEnv;
  external Pointer<Void> attachCurrentThreadAsDaemon;
}
