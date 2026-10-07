# aud_midi_android: Dart reaches the shim classes through JNI by name and
# implements the listener interfaces through java.lang.reflect.Proxy, so R8
# must neither remove nor rename them.
-keep class com.audanika.aud_midi_android.** { *; }
