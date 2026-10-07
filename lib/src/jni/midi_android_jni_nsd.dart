// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// coverage:ignore-file
// Reason: JNI glue to NsdManager; it runs on Android only. The registration
// flow behind it is tested with fakes in
// midi_android_service_advertiser_test.dart.

import 'dart:io';

import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:jni/jni.dart';

import '../platform/midi_android_nsd.dart';
import 'midi_android_jni_bindings.g.dart';

// #############################################################################
/// The [MidiAndroidNsd] of a real Android device: `NsdManager`.
final class MidiAndroidJniNsd implements MidiAndroidNsd {
  /// Creates the registrar of the application [context]; null uses the
  /// context the shim captured at app start.
  ///
  /// Throws [MidiUnsupported] outside Android and when no context exists.
  factory MidiAndroidJniNsd({JObject? context}) {
    if (!Platform.isAndroid) {
      throw const MidiUnsupported('NsdManager outside Android');
    }
    final app = context?.as(Context.type) ?? AudMidiContext.get();
    final manager = app == null ? null : AudMidiContext.nsdManager(app);
    if (manager == null) {
      throw const MidiUnsupported('NsdManager without a context');
    }
    return MidiAndroidJniNsd._(manager);
  }

  MidiAndroidJniNsd._(this._manager);

  // ...........................................................................
  @override
  void Function() register({
    required String name,
    required String type,
    required int port,
    required Map<String, String> txt,
    required void Function(String name) onRegistered,
    required void Function(int errorCode) onRegistrationFailed,
    required void Function() onUnregistered,
    required void Function(int errorCode) onUnregistrationFailed,
  }) {
    final listener = NsdManager$RegistrationListener.implement(
      $NsdManager$RegistrationListener(
        onServiceRegistered: (info) {
          final actual = info?.serviceName?.toDartString(releaseOriginal: true);
          info?.release();
          onRegistered(actual ?? name);
        },
        onServiceRegistered$async: true,
        onRegistrationFailed: (info, errorCode) {
          info?.release();
          onRegistrationFailed(errorCode);
        },
        onRegistrationFailed$async: true,
        onServiceUnregistered: (info) {
          info?.release();
          onUnregistered();
        },
        onServiceUnregistered$async: true,
        onUnregistrationFailed: (info, errorCode) {
          info?.release();
          onUnregistrationFailed(errorCode);
        },
        onUnregistrationFailed$async: true,
      ),
    );
    using((arena) {
      final info = NsdServiceInfo()..releasedBy(arena);
      info
        ..serviceName = (name.toJString()..releasedBy(arena))
        ..serviceType = (type.toJString()..releasedBy(arena))
        ..port = port;
      for (final entry in txt.entries) {
        info.setAttribute(
          entry.key.toJString()..releasedBy(arena),
          entry.value.toJString()..releasedBy(arena),
        );
      }
      _manager.registerService(info, NsdManager.PROTOCOL_DNS_SD, listener);
    });
    return () {
      try {
        _manager.unregisterService(listener);
      } on JThrowable {
        // Never registered, e.g. after a timeout: nothing to withdraw.
        onUnregistered();
      }
      listener.release();
    };
  }

  // ...........................................................................
  final NsdManager _manager;
}
