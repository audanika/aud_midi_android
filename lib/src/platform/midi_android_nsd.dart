// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
/// Registers network services with Android's DNS-SD registrar, `NsdManager`.
abstract interface class MidiAndroidNsd {
  // ...........................................................................
  /// Registers the service [name] of [type] on [port] with the TXT entries
  /// [txt] and returns a function that unregisters it.
  ///
  /// The callbacks run later in this isolate:
  /// - [onRegistered] with the name the registrar chose, which differs from
  ///   [name] after a conflict.
  /// - [onRegistrationFailed] with the `NsdManager` error code.
  /// - [onUnregistered] after the unregistration.
  /// - [onUnregistrationFailed] with the `NsdManager` error code.
  void Function() register({
    required String name,
    required String type,
    required int port,
    required Map<String, String> txt,
    required void Function(String name) onRegistered,
    required void Function(int errorCode) onRegistrationFailed,
    required void Function() onUnregistered,
    required void Function(int errorCode) onUnregistrationFailed,
  });
}
