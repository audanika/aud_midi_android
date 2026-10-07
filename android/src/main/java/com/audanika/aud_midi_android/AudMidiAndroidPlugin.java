// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * The Flutter plugin entry of aud_midi_android.
 *
 * <p>It registers no channel: Dart reaches the shim through JNI. The class only
 * exists so that Flutter builds the shim into the app.
 */
public final class AudMidiAndroidPlugin implements FlutterPlugin {
  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {}

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {}
}
