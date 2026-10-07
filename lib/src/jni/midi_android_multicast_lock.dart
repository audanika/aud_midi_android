// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// coverage:ignore-file
// Reason: JNI glue to WifiManager.MulticastLock; it runs on Android only.

import 'dart:io';

import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';
import 'package:jni/jni.dart';

import 'midi_android_jni_bindings.g.dart';

// #############################################################################
/// Lets multicast packets through the Wi-Fi filter of Android while held.
///
/// Android drops multicast packets addressed to the device to save power;
/// browsing for `_apple-midi._udp` with mDNS needs this lock while it runs.
/// The app declares `android.permission.CHANGE_WIFI_MULTICAST_STATE`.
final class MidiAndroidMulticastLock {
  /// Creates the lock named [tag] for the application [context]; null uses
  /// the context the shim captured at app start.
  ///
  /// Throws [MidiUnsupported] outside Android and without Wi-Fi.
  factory MidiAndroidMulticastLock({
    String tag = 'aud_midi',
    JObject? context,
  }) {
    if (!Platform.isAndroid) {
      throw const MidiUnsupported('WifiManager.MulticastLock outside Android');
    }
    final app = context?.as(Context.type) ?? AudMidiContext.get();
    final wifi = app == null ? null : AudMidiContext.wifiManager(app);
    final lock = using(
      (arena) => wifi?.createMulticastLock(tag.toJString()..releasedBy(arena)),
    );
    wifi?.release();
    if (lock == null) {
      throw const MidiUnsupported('WifiManager.MulticastLock without Wi-Fi');
    }
    lock.referenceCounted = false;
    return MidiAndroidMulticastLock._(lock);
  }

  MidiAndroidMulticastLock._(this._lock);

  // ...........................................................................
  /// Takes the lock.
  ///
  /// Throws [MidiPermissionDenied] when the app lacks
  /// `CHANGE_WIFI_MULTICAST_STATE`.
  void acquire() {
    try {
      _lock.acquire();
    } on JThrowable {
      throw const MidiPermissionDenied(MidiPermission.localNetwork);
    }
  }

  /// Gives the lock back.
  void release() {
    if (_lock.isHeld) _lock.release$1();
  }

  /// Gives the lock back and frees it; it cannot be used afterwards.
  void dispose() {
    release();
    _lock.release();
  }

  // ...........................................................................
  /// Whether the lock is held.
  bool get isHeld => _lock.isHeld;

  // ...........................................................................
  final WifiManager$MulticastLock _lock;
}
