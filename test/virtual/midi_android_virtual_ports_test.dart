// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';
import 'package:test/test.dart';

void main() {
  MidiPortInfo port(String id, MidiDirection direction, {bool own = true}) =>
      MidiPortInfo(
        id: MidiPortId(id),
        name: id,
        direction: direction,
        isOwn: own,
      );

  final ports = [
    port('in A', MidiDirection.input),
    port('in B', MidiDirection.input),
    port('out A', MidiDirection.output),
    port('other in', MidiDirection.input, own: false),
  ];

  late List<MidiPortId> closed;
  late MidiAndroidVirtualPorts virtualPorts;

  MidiVirtualPortSpec spec(String name, MidiDirection direction) =>
      MidiVirtualPortSpec(name: name, direction: direction);

  setUp(() {
    closed = [];
    virtualPorts = MidiAndroidVirtualPorts(
      ports: () => ports,
      closePort: (port) async => closed.add(port),
    );
  });

  group('MidiAndroidVirtualPorts', () {
    group('create(spec)', () {
      test('hands out the declared port named like the spec', () async {
        final created = await virtualPorts.create(
          spec('in B', MidiDirection.input),
        );
        expect(created.id, const MidiPortId('in B'));
      });

      test('hands out the first free port of the direction', () async {
        final first = await virtualPorts.create(spec('x', MidiDirection.input));
        final second = await virtualPorts.create(
          spec('x', MidiDirection.input),
        );
        expect(
          [first.id, second.id],
          [const MidiPortId('in A'), const MidiPortId('in B')],
        );
        expect(virtualPorts.claimed, {first.id, second.id});
      });

      test('throws MidiUnsupported when no declared port is left', () async {
        await virtualPorts.create(spec('out A', MidiDirection.output));
        await expectLater(
          virtualPorts.create(spec('out B', MidiDirection.output)),
          throwsA(
            isA<MidiUnsupported>().having(
              (e) => e.feature,
              'feature',
              contains('AudMidiDeviceService'),
            ),
          ),
        );
      });
    });

    group('remove(port)', () {
      test('gives the port back and closes it', () async {
        final created = await virtualPorts.create(
          spec('out A', MidiDirection.output),
        );
        await virtualPorts.remove(created.id);
        expect(closed, [created.id]);
        expect(virtualPorts.claimed, isEmpty);
        expect(
          (await virtualPorts.create(spec('y', MidiDirection.output))).id,
          created.id,
        );
      });

      test('throws MidiPortGone for a port not handed out', () async {
        await expectLater(
          virtualPorts.remove(const MidiPortId('in A')),
          throwsA(isA<MidiPortGone>()),
        );
      });
    });
  });
}
