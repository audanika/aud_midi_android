// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:typed_data';

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';

/// Runs the checks of the example against the loopback devices declared in
/// the manifest and returns the report, one line per entry; [log] gets the
/// lines as they come.
///
/// Meant to run in a background isolate, like the MIDI isolate of aud_midi.
Future<List<String>> runLoopbackReport({
  void Function(String line)? log,
}) async {
  final report = _Report(log);
  _trace = log;
  final host = ReportHost();
  final backend = AndroidMidiBackend();
  try {
    await backend.start(host);
  } on MidiException catch (error) {
    return [...report..add('start failed: $error')];
  }
  report
    ..add('capabilities: ${backend.capabilities}')
    ..add('ports: ${backend.ports.length}');
  for (final port in backend.ports) {
    report.add(
      '  ${port.id} "${port.name}" ${port.direction.name} '
      '${port.transport.name} ${port.protocol.name} '
      'ump=${port.capabilities.ump} own=${port.isOwn} '
      'scheduled=${port.capabilities.scheduledSend}',
    );
  }
  await _check(report, 'byte loopback', () => _byteLoopback(backend, host));
  await _check(report, 'UMP loopback', () => _umpLoopback(backend, host));
  await _check(report, 'virtual ports', () => _virtualPorts(backend, host));
  await _check(report, 'bluetooth', () => _bluetooth(backend));
  await _check(report, 'nsd', _advertise);
  await _check(report, 'multicast lock', _multicastLock);
  report.add('diagnostics: ${host.diagnostics}');
  await backend.stop();
  report.add('stopped');
  await _check(report, 'MidiEngine over AndroidMidiBackend', _engine);
  return [...report];
}

void Function(String line)? _trace;

// #############################################################################
/// The lines of the report, passed on to a log as they are added.
final class _Report extends Iterable<String> {
  _Report(this._log);

  final void Function(String line)? _log;
  final List<String> _lines = [];

  void add(String line) {
    _lines.add(line);
    _log?.call(line);
  }

  void addAll(Iterable<String> lines) => lines.forEach(add);

  @override
  Iterator<String> get iterator => _lines.iterator;
}

// #############################################################################
/// Collects what the backend reports.
final class ReportHost implements MidiBackendHost {
  @override
  final MidiClock clock = const MidiSystemClock();

  /// The packets per port with the time they arrived.
  final Map<MidiPortId, List<(MidiPacket, MidiTime)>> packets = {};

  /// The diagnostics.
  final List<MidiDiagnostic> diagnostics = [];

  /// The port events.
  final List<MidiPortEvent> events = [];

  @override
  void portsChanged(List<MidiPortEvent> events) => this.events.addAll(events);

  @override
  void received(MidiPortId port, MidiPacket packet) =>
      (packets[port] ??= []).add((packet, clock.now()));

  @override
  void diagnostic(MidiDiagnostic diagnostic) => diagnostics.add(diagnostic);

  /// Returns the bytes received on [port] in order.
  List<int> bytesOf(MidiPortId port) => [
    for (final (packet, _) in packets[port] ?? const <(MidiPacket, MidiTime)>[])
      if (packet is MidiBytesPacket) ...packet.bytes.bytes,
  ];

  /// Returns the UMP words received on [port] in order.
  List<int> wordsOf(MidiPortId port) => [
    for (final (packet, _) in packets[port] ?? const <(MidiPacket, MidiTime)>[])
      if (packet is MidiUmpPacket) ...packet.words,
  ];

  /// Waits until [done] holds or [timeout] passed.
  Future<void> waitFor(
    bool Function() done, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final end = clock.now() + timeout;
    while (!done() && clock.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }
}

Future<void> _check(
  _Report report,
  String name,
  Future<List<String>> Function() check,
) async {
  report.add('$name:');
  try {
    report.addAll((await check()).map((line) => '  $line'));
  } on Object catch (error) {
    report.add('  failed: $error');
  }
}

Future<List<String>> _byteLoopback(
  AndroidMidiBackend backend,
  ReportHost host,
) async {
  final input = _port(backend, 'loop out', MidiDirection.input);
  final output = _port(backend, 'loop in', MidiDirection.output);
  if (input == null || output == null) return ['loopback device not found'];
  _trace?.call('  opening ${input.id}');
  await backend.openPort(input.id);
  _trace?.call('  opening ${output.id}');
  await backend.openPort(output.id);
  _trace?.call('  sending');
  final sysEx = [0xf0, 0x7d, for (var i = 0; i < 3000; i++) i & 0x7f, 0xf7];
  final messages = [
    MidiBytes.fromHex('90 3c 64'),
    MidiBytes.fromHex('b0 07 7f'),
    MidiBytes.fromHex('e0 00 40'),
    MidiBytes.fromHex('80 3c 00'),
    MidiBytes(sysEx),
  ];
  final sent = <MidiBytesPacket>[];
  for (final message in messages) {
    final packet = MidiBytesPacket(bytes: message, time: host.clock.now());
    sent.add(packet);
    await backend.send(output.id, packet);
  }
  final scheduled = MidiBytesPacket(
    bytes: MidiBytes.fromHex('90 40 50'),
    time: host.clock.now() + const Duration(milliseconds: 200),
  );
  await backend.send(output.id, scheduled);
  final expected = [
    for (final packet in [...sent, scheduled]) ...packet.bytes.bytes,
  ];
  await host.waitFor(() => host.bytesOf(input.id).length >= expected.length);
  final received = host.packets[input.id] ?? const [];
  final last = received.isEmpty ? null : received.last;
  await backend.cancelPending(output.id);
  return [
    'send path: ${backend.sendPath(output.id)}, cancelPending: ok',
    'bytes sent ${expected.length}, received '
        '${host.bytesOf(input.id).length} in ${received.length} packets',
    'equal and in order: ${_equal(host.bytesOf(input.id), expected)}',
    'timestamps of the first four packets minus send time (us): '
        '${[for (var i = 0; i < 4 && i < received.length; i++) received[i].$1.time.difference(sent[i].time).inMicroseconds]}',
    'delivery latency of the first four packets (us): '
        '${[for (var i = 0; i < 4 && i < received.length; i++) received[i].$2.difference(received[i].$1.time).inMicroseconds]}',
    if (last != null)
      'scheduled packet: timestamp minus due time '
          '${last.$1.time.difference(scheduled.time).inMicroseconds} us, '
          'arrived ${scheduled.time.difference(last.$2).inMilliseconds} ms '
          'before due (a virtual device does not schedule)',
  ];
}

Future<List<String>> _umpLoopback(
  AndroidMidiBackend backend,
  ReportHost host,
) async {
  final input = _port(backend, 'ump loop', MidiDirection.input);
  final output = _port(backend, 'ump loop', MidiDirection.output);
  if (input == null || output == null) return ['UMP loopback not found'];
  await backend.openPort(input.id);
  await backend.openPort(output.id);
  final packets = [
    [0x40903c00, 0xc0000000],
    [0x20903c64],
    [0xf0000101, 0x0000001f, 0, 0],
    [
      for (var i = 0; i < 300; i++) ...[0x40900000 | (i & 0x7f) << 8, i],
    ],
  ];
  final sent = <MidiUmpPacket>[];
  for (final words in packets) {
    final packet = MidiUmpPacket(words: words, time: host.clock.now());
    sent.add(packet);
    await backend.send(output.id, packet);
  }
  final expected = [for (final packet in sent) ...packet.words];
  await host.waitFor(() => host.wordsOf(input.id).length >= expected.length);
  final received = host.packets[input.id] ?? const [];
  return [
    'protocol ${output.protocol.name}, send path: '
        '${backend.sendPath(output.id)}',
    'words sent ${expected.length}, received '
        '${host.wordsOf(input.id).length} in ${received.length} packets',
    'equal and in order: ${_equal(host.wordsOf(input.id), expected)}',
    'timestamp of the first packet minus send time (us): '
        '${received.isEmpty ? '-' : received.first.$1.time.difference(sent.first.time).inMicroseconds}',
  ];
}

Future<List<String>> _virtualPorts(
  AndroidMidiBackend backend,
  ReportHost host,
) async {
  final ownIn = await backend.virtualPorts.create(
    MidiVirtualPortSpec(name: 'virtual in', direction: MidiDirection.input),
  );
  final umpLines = await _ownUmpDevice(backend, host);
  final ownOut = await backend.virtualPorts.create(
    MidiVirtualPortSpec(name: 'virtual out', direction: MidiDirection.output),
  );
  await backend.openPort(ownIn.id);
  await backend.openPort(ownOut.id);
  // Another client of the app's own virtual device, as another app would be.
  final platform = MidiAndroidJniPlatform();
  final device = platform.devices().firstWhere((d) => d.ownService != null);
  final client = await platform.openDevice(device.id);
  if (client == null) return ['the own device cannot be opened as client'];
  final clientBytes = <int>[];
  late final MidiAndroidReceiver clientReceiver;
  clientReceiver = client.openOutputPort(
    port: 0,
    onData: () {
      final data = clientReceiver.drain();
      if (data == null) return;
      for (final chunk
          in const MidiAndroidReceiveDecoder().decode(data).chunks) {
        clientBytes.addAll(chunk.bytes);
      }
    },
  )!;
  final clientSender = client.openJavaInputPort(0)!;
  // Timestamp 0: the shim's receiver stamps the data with System.nanoTime().
  clientSender
    ..send(Uint8List.fromList([0x90, 0x30, 0x40]), timestampNanos: 0)
    ..flush();
  await host.waitFor(() => host.bytesOf(ownIn.id).length >= 3);
  final (stamped, arrived) = host.packets[ownIn.id]!.first;
  await backend.send(
    ownOut.id,
    MidiBytesPacket(
      bytes: MidiBytes.fromHex('b0 01 02'),
      time: host.clock.now(),
    ),
  );
  await host.waitFor(() => clientBytes.length >= 3);
  final lines = [
    'own ports: ${ownIn.id} (${ownIn.direction.name}), '
        '${ownOut.id} (${ownOut.direction.name})',
    'other app -> own input: ${_hex(host.bytesOf(ownIn.id))}, '
        'arrival minus System.nanoTime() stamp: '
        '${arrived.difference(stamped.time).inMicroseconds} us',
    'own output -> other app: ${_hex(clientBytes)}',
  ];
  clientSender.close();
  clientReceiver.close();
  client.close();
  platform.dispose();
  return [...lines, ...umpLines];
}

Future<List<String>> _ownUmpDevice(
  AndroidMidiBackend backend,
  ReportHost host,
) async {
  final ownIn = await backend.virtualPorts.create(
    MidiVirtualPortSpec(
      name: 'ump virtual',
      direction: MidiDirection.input,
      protocol: MidiProtocol.midi2,
    ),
  );
  final ownOut = await backend.virtualPorts.create(
    MidiVirtualPortSpec(
      name: 'ump virtual',
      direction: MidiDirection.output,
      protocol: MidiProtocol.midi2,
    ),
  );
  await backend.openPort(ownIn.id);
  await backend.openPort(ownOut.id);
  final platform = MidiAndroidJniPlatform();
  final device = platform.devices().firstWhere(
    (d) =>
        d.ownService == 'com.audanika.aud_midi_android.AudMidiUmpDeviceService',
  );
  final client = await platform.openDevice(device.id);
  if (client == null) return ['the own UMP device cannot be opened'];
  final clientWords = <int>[];
  final assembler = MidiAndroidUmpAssembler();
  late final MidiAndroidReceiver clientReceiver;
  clientReceiver = client.openOutputPort(
    port: 0,
    onData: () {
      final data = clientReceiver.drain();
      if (data == null) return;
      for (final chunk
          in const MidiAndroidReceiveDecoder().decode(data).chunks) {
        clientWords.addAll(assembler.add(chunk.bytes));
      }
    },
  )!;
  final clientSender =
      client.openNativeInputPort(0) ?? client.openJavaInputPort(0)!;
  clientSender.send(
    MidiAndroidPacketEncoder.pack(const [0x40903c00, 0xc0000000]),
    timestampNanos: platform.monotonicMicros() * 1000,
  );
  await host.waitFor(() => host.wordsOf(ownIn.id).length >= 2);
  await backend.send(
    ownOut.id,
    MidiUmpPacket(words: const [0x20b00102], time: host.clock.now()),
  );
  await host.waitFor(() => clientWords.isNotEmpty);
  final lines = [
    'own UMP ports: ${ownIn.id} ump=${ownIn.capabilities.ump}, '
        '${ownOut.id}',
    'other app -> own UMP input: '
        '${host.wordsOf(ownIn.id).map((w) => w.toRadixString(16))}',
    'own UMP output -> other app (${clientSender.kind}): '
        '${clientWords.map((w) => w.toRadixString(16))}',
  ];
  clientSender.close();
  clientReceiver.close();
  client.close();
  platform.dispose();
  return lines;
}

Future<List<String>> _engine() async {
  final engine = MidiEngine(backend: AndroidMidiBackend());
  await engine.open();
  try {
    MidiPortId find(String name, MidiDirection direction) => engine.ports
        .firstWhere((p) => p.name == name && p.direction == direction)
        .id;
    final input = await engine.openInput(find('loop out', MidiDirection.input));
    final output = await engine.openOutput(
      find('loop in', MidiDirection.output),
    );
    final events = <MidiEvent>[];
    final subscription = input.events.listen(events.add);
    final messages = <MidiMessage>[
      const MidiNoteOn(channel: 0, note: 60, velocity: 100),
      const MidiControlChange(channel: 1, controller: 7, value: 99),
      MidiSysEx([0x7d, 1, 2, 3]),
    ];
    for (final message in messages) {
      await output.send(message);
    }
    // The virtual loopback does not schedule: the engine times the note.
    final due = engine.clock.now() + const Duration(milliseconds: 100);
    await output.send(const MidiNoteOff(channel: 0, note: 60), at: due);
    final end = engine.clock.now() + const Duration(seconds: 3);
    while (events.length < 4 && engine.clock.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    final umpInput = await engine.openInput(
      find('ump loop', MidiDirection.input),
    );
    final umpOutput = await engine.openOutput(
      find('ump loop', MidiDirection.output),
    );
    final umpEvents = <MidiEvent>[];
    final umpSubscription = umpInput.events.listen(umpEvents.add);
    await umpOutput.send(
      const MidiNoteOn2(channel: 2, note: 64, velocity: 0x8000),
    );
    // A MIDI 1.0 message to a MIDI 2.0 port: the engine translates it.
    await umpOutput.send(const MidiNoteOn(channel: 3, note: 65, velocity: 64));
    final umpEnd = engine.clock.now() + const Duration(seconds: 3);
    while (umpEvents.length < 2 && engine.clock.now().isBefore(umpEnd)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await subscription.cancel();
    await umpSubscription.cancel();
    final received = [for (final event in events) event.message];
    return [
      'bytes: sent ${messages.length + 1} messages, received '
          '${received.length}, equal and in order: '
          '${_equal(received, [...messages, const MidiNoteOff(channel: 0, note: 60)])}',
      if (events.length == 4)
        'software-scheduled note: received '
            '${events.last.time.difference(due).inMicroseconds} us after due',
      'UMP: received ${[for (final event in umpEvents) event.message]}',
    ];
  } finally {
    await engine.close();
  }
}

Future<List<String>> _bluetooth(AndroidMidiBackend backend) async {
  final bluetooth = backend.bluetooth;
  if (bluetooth == null) return ['no Bluetooth LE'];
  try {
    final found = await bluetooth
        .scan(timeout: const Duration(seconds: 2))
        .toList();
    return ['scan of 2 s found ${found.length} BLE-MIDI peripherals'];
  } on MidiException catch (error) {
    return ['scan refused: $error'];
  }
}

Future<List<String>> _advertise() async {
  final registration = await MidiAndroidServiceAdvertiser().register(
    name: 'aud_midi example',
    type: '_apple-midi._udp',
    port: 5004,
  );
  final name = registration.name;
  await registration.unregister();
  return ['registered and unregistered "$name"'];
}

Future<List<String>> _multicastLock() async {
  final lock = MidiAndroidMulticastLock()..acquire();
  final held = lock.isHeld;
  lock.dispose();
  return ['held after acquire: $held'];
}

MidiPortInfo? _port(
  AndroidMidiBackend backend,
  String name,
  MidiDirection direction,
) => backend.ports
    .where((port) => port.name == name && port.direction == direction)
    .firstOrNull;

bool _equal(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
