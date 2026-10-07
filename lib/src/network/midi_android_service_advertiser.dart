// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import 'package:aud_midi_core/aud_midi_core.dart';

import '../jni/midi_android_jni_nsd.dart';
import '../logic/midi_android_error_codes.dart';
import '../platform/midi_android_nsd.dart';

// #############################################################################
/// Advertises network MIDI sessions through Android's `NsdManager`, e.g. the
/// `_apple-midi._udp` session the umbrella composes from `aud_midi_network`.
///
/// Receiving the mDNS answers of other hosts additionally needs a
/// `MidiAndroidMulticastLock` while browsing.
final class MidiAndroidServiceAdvertiser implements MidiServiceAdvertiser {
  /// Creates the advertiser.
  ///
  /// - [nsd] replaces `NsdManager`, e.g. with a fake in tests.
  /// - [timeout] how long a registration may take.
  MidiAndroidServiceAdvertiser({
    MidiAndroidNsd? nsd,
    this.timeout = const Duration(seconds: 10),
  }) : _nsd = nsd ?? MidiAndroidJniNsd();

  // ...........................................................................
  /// Registers the service and completes with the name the registrar chose.
  ///
  /// Throws a [MidiNativeError] with the `NsdManager` error code when the
  /// registration fails, with [MidiAndroidErrorCodes.timeout] when it takes
  /// longer than [timeout].
  @override
  Future<MidiServiceRegistration> register({
    required String name,
    required String type,
    required int port,
    Map<String, String> txt = const {},
  }) async {
    final registered = Completer<String>();
    final registration = _MidiAndroidServiceRegistration(timeout: timeout);
    final unregister = _nsd.register(
      name: name,
      type: type,
      port: port,
      txt: txt,
      onRegistered: (name) {
        if (!registered.isCompleted) registered.complete(name);
      },
      onRegistrationFailed: (code) {
        if (registered.isCompleted) return;
        registered.completeError(
          MidiNativeError(api: _registerApi, code: code),
        );
      },
      onUnregistered: registration.unregistered,
      onUnregistrationFailed: registration.unregistrationFailed,
    );
    registration.name = await registered.future.timeout(
      timeout,
      onTimeout: () {
        unregister();
        throw const MidiNativeError(
          api: _registerApi,
          code: MidiAndroidErrorCodes.timeout,
        );
      },
    );
    registration.unregisterNative = unregister;
    return registration;
  }

  // ...........................................................................
  /// How long a registration or unregistration may take.
  final Duration timeout;

  // ...........................................................................
  static const _registerApi = 'NsdManager.registerService';
  final MidiAndroidNsd _nsd;
}

// #############################################################################
final class _MidiAndroidServiceRegistration implements MidiServiceRegistration {
  _MidiAndroidServiceRegistration({required this.timeout});

  final Duration timeout;

  @override
  String name = '';

  late final void Function() unregisterNative;

  Completer<void>? _completer;

  Future<void>? _unregistering;

  @override
  Future<void> unregister() => _unregistering ??= _unregister();

  void unregistered() {
    final completer = _completer;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  void unregistrationFailed(int code) {
    final completer = _completer;
    if (completer == null || completer.isCompleted) return;
    completer.completeError(MidiNativeError(api: _unregisterApi, code: code));
  }

  Future<void> _unregister() {
    final completer = _completer = Completer<void>();
    unregisterNative();
    return completer.future.timeout(
      timeout,
      onTimeout: () => throw const MidiNativeError(
        api: _unregisterApi,
        code: MidiAndroidErrorCodes.timeout,
      ),
    );
  }

  static const _unregisterApi = 'NsdManager.unregisterService';
}
