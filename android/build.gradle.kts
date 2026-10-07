// The Java shim of aud_midi_android: callbacks Dart cannot implement through
// jnigen, the MIDI device services and the context provider. Flutter builds
// this library into every Android app that depends on the package.

group = "com.audanika.aud_midi_android"
version = "1.0"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.audanika.aud_midi_android"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 24
        // R8 must keep the shim: Dart reaches it through JNI by name.
        consumerProguardFiles("consumer-rules.pro")
    }
}
