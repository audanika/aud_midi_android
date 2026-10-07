// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';
import 'package:test/test.dart';

void main() {
  const input = MidiAndroidPortDescription.typeInput;
  const output = MidiAndroidPortDescription.typeOutput;
  const keys = MidiAndroidDeviceDescription(
    id: 1,
    type: MidiAndroidDeviceDescription.typeUsb,
    name: 'Keys',
    ports: [MidiAndroidPortDescription(type: output, number: 0)],
  );
  const pads = MidiAndroidDeviceDescription(
    id: 2,
    type: MidiAndroidDeviceDescription.typeUsb,
    name: 'Pads',
    ports: [MidiAndroidPortDescription(type: input, number: 0)],
  );
  const keysIn = MidiPortId('android:1:in:0');
  const padsOut = MidiPortId('android:2:out:0');

  late MidiAndroidPortTable table;

  List<String> describe(List<MidiPortEvent> events) => [
    for (final event in events) '${event.runtimeType} ${event.port.id}',
  ];

  setUp(() => table = MidiAndroidPortTable());

  group('MidiAndroidPortTable', () {
    group('sync(devices)', () {
      test('reports removed, changed and added ports in this order', () {
        expect(describe(table.sync(const [keys])), [
          'MidiPortAdded android:1:in:0',
        ]);
        const renamed = MidiAndroidDeviceDescription(
          id: 1,
          type: MidiAndroidDeviceDescription.typeUsb,
          name: 'Keys 2',
          ports: [MidiAndroidPortDescription(type: output, number: 0)],
        );
        table.add(pads);
        expect(describe(table.sync(const [renamed])), [
          'MidiPortRemoved android:2:out:0',
          'MidiPortChanged android:1:in:0',
        ]);
        final changed = table.sync(const [renamed, pads]);
        expect(describe(changed), ['MidiPortAdded android:2:out:0']);
      });

      test('reports the previous port of a change', () {
        table.sync(const [keys]);
        const renamed = MidiAndroidDeviceDescription(
          id: 1,
          type: MidiAndroidDeviceDescription.typeUsb,
          name: 'Other',
          ports: [MidiAndroidPortDescription(type: output, number: 0)],
        );
        final event = table.sync(const [renamed]).single as MidiPortChanged;
        expect(event.previous.name, 'Keys');
        expect(event.port.name, 'Other');
      });
    });

    group('add(device)', () {
      test('reports nothing for a device known already', () {
        table.add(keys);
        expect(table.add(keys), isEmpty);
      });
    });

    group('remove(id)', () {
      test('reports the ports of the device as removed', () {
        table
          ..add(keys)
          ..add(pads);
        expect(describe(table.remove(1)), ['MidiPortRemoved android:1:in:0']);
        expect(table.remove(1), isEmpty);
      });
    });

    group('port(id), deviceOf(id), device(id), portsOf(id)', () {
      test('find what is known', () {
        table
          ..add(keys)
          ..add(pads);
        expect(table.port(keysIn)?.name, 'Keys');
        expect(table.port(const MidiPortId('android:9:in:0')), isNull);
        expect(table.deviceOf(padsOut), same(pads));
        expect(table.deviceOf(const MidiPortId('android:9:in:0')), isNull);
        expect(table.device(1), same(keys));
        expect(table.device(9), isNull);
        expect(table.portsOf(2).map((port) => port.id).toList(), [padsOut]);
        expect(table.portsOf(9), isEmpty);
      });
    });

    group('ports, devices, mapper', () {
      test('list what is known', () {
        table
          ..add(keys)
          ..add(pads);
        expect(table.ports.map((port) => port.id).toList(), [keysIn, padsOut]);
        expect(table.devices, [keys, pads]);
        expect(table.mapper.backend, 'android');
      });
    });
  });
}
