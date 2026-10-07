// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
/// The codes of the `MidiNativeError`s the backend throws when an Android
/// call failed without an error code of its own.
///
/// Calls with a code of their own, e.g. AMidi's `media_status_t` or the
/// `NsdManager` failures, pass that code on.
abstract final class MidiAndroidErrorCodes {
  // ...........................................................................
  /// Android returned null instead of an object: the device or port is
  /// busy, missing or gone.
  static const int unavailable = -1;

  /// Android did not answer within the time allowed.
  static const int timeout = -2;
}
