// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

package com.audanika.aud_midi_android;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.net.Uri;

/**
 * Captures the application context when the app process starts, before any
 * Dart code runs. It serves no data.
 */
public final class AudMidiContextProvider extends ContentProvider {
  @Override
  public boolean onCreate() {
    AudMidiContext.set(getContext());
    return true;
  }

  @Override
  public Cursor query(
      Uri uri, String[] projection, String selection, String[] args, String order) {
    return null;
  }

  @Override
  public String getType(Uri uri) {
    return null;
  }

  @Override
  public Uri insert(Uri uri, ContentValues values) {
    return null;
  }

  @Override
  public int delete(Uri uri, String selection, String[] args) {
    return 0;
  }

  @Override
  public int update(Uri uri, ContentValues values, String selection, String[] args) {
    return 0;
  }
}
