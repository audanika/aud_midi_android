// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:isolate';

import 'package:flutter/material.dart';

import 'loopback_report.dart';

/// Runs the loopback checks of aud_midi_android in a background isolate and
/// shows the report; every line also goes to logcat, tagged
/// `AUD_MIDI_REPORT`.
void main() => runApp(const LoopbackApp());

/// The app that shows the report.
class LoopbackApp extends StatefulWidget {
  /// Creates the app.
  const LoopbackApp({super.key});

  @override
  State<LoopbackApp> createState() => _LoopbackAppState();
}

class _LoopbackAppState extends State<LoopbackApp> {
  List<String> _report = const [];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final lines = ReceivePort();
    debugPrint('AUD_MIDI_REPORT begin');
    await Isolate.spawn(_reportInIsolate, lines.sendPort);
    await for (final line in lines) {
      if (line == _done) break;
      debugPrint('AUD_MIDI_REPORT $line');
      if (mounted) setState(() => _report = [..._report, '$line']);
    }
    lines.close();
    debugPrint('AUD_MIDI_REPORT end');
  }

  static const _done = '<done>';

  static Future<void> _reportInIsolate(SendPort lines) async {
    try {
      await runLoopbackReport(log: lines.send);
    } on Object catch (error, stack) {
      lines
        ..send('isolate failed: $error')
        ..send('$stack');
    }
    lines.send(_done);
    Isolate.exit();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('aud_midi_android loopback')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final line in _report)
            Text(line, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    ),
  );
}
