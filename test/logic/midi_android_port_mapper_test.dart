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
  const mapper = MidiAndroidPortMapper();
  const input = MidiAndroidPortDescription.typeInput;
  const output = MidiAndroidPortDescription.typeOutput;

  MidiAndroidDeviceDescription device({
    int type = MidiAndroidDeviceDescription.typeUsb,
    int transport = MidiAndroidDeviceDescription.transportByteStream,
    int defaultProtocol = MidiAndroidDeviceDescription.protocolUnknown,
    String name = 'Keys',
    String product = '',
    String? ownService,
    String bluetoothAddress = '',
    List<MidiAndroidPortDescription> ports = const [
      MidiAndroidPortDescription(type: input, number: 0, name: 'In'),
      MidiAndroidPortDescription(type: output, number: 0, name: 'Out'),
    ],
  }) => MidiAndroidDeviceDescription(
    id: 5,
    type: type,
    transport: transport,
    defaultProtocol: defaultProtocol,
    name: name,
    manufacturer: 'Acme',
    product: product,
    serialNumber: 'S1',
    version: '1.0',
    ports: ports,
    ownService: ownService,
    bluetoothAddress: bluetoothAddress,
  );

  group('MidiAndroidPortMapper', () {
    group('ports(device)', () {
      test('turns Android input ports into outputs of the app', () {
        expect(mapper.ports(device()), [
          MidiPortInfo(
            id: const MidiPortId('android:5:out:0'),
            deviceId: const MidiDeviceId('android:5'),
            name: 'In',
            manufacturer: 'Acme',
            direction: MidiDirection.output,
            transport: MidiTransport.usb,
            capabilities: const MidiPortCapabilities(
              scheduledSend: true,
              cancelPending: true,
            ),
            serialNumber: 'S1',
          ),
          MidiPortInfo(
            id: const MidiPortId('android:5:in:0'),
            deviceId: const MidiDeviceId('android:5'),
            name: 'Out',
            manufacturer: 'Acme',
            direction: MidiDirection.input,
            transport: MidiTransport.usb,
            capabilities: const MidiPortCapabilities(timestampsIn: true),
            serialNumber: 'S1',
          ),
        ]);
      });

      test('keeps the directions of own virtual devices', () {
        final ports = mapper.ports(
          device(
            type: MidiAndroidDeviceDescription.typeVirtual,
            ownService: 'com.example.Service',
          ),
        );
        expect(
          [
            for (final port in ports)
              (port.id.value, port.direction, port.isOwn, port.isVirtual),
          ],
          [
            (
              'android:own:com.example.Service:in:0',
              MidiDirection.input,
              true,
              true,
            ),
            (
              'android:own:com.example.Service:out:0',
              MidiDirection.output,
              true,
              true,
            ),
          ],
        );
      });

      test('names ports without a name after the device', () {
        final ports = mapper.ports(
          device(
            ports: const [
              MidiAndroidPortDescription(type: input, number: 0),
              MidiAndroidPortDescription(type: input, number: 1),
              MidiAndroidPortDescription(type: output, number: 0),
            ],
          ),
        );
        expect(ports.map((port) => port.name).toList(), [
          'Keys 1',
          'Keys 2',
          'Keys',
        ]);
      });

      test('keeps the Android details in native', () {
        final port = mapper.ports(
          device(
            type: MidiAndroidDeviceDescription.typeBluetooth,
            bluetoothAddress: 'AA:BB',
          ),
        )[1];
        expect(port.native, {
          'androidDeviceId': 5,
          'androidType': MidiAndroidDeviceDescription.typeBluetooth,
          'androidTransport': MidiAndroidDeviceDescription.transportByteStream,
          'androidDefaultProtocol': -1,
          'androidVersion': '1.0',
          'androidPrivate': false,
          'bluetoothAddress': 'AA:BB',
          'androidPortType': output,
          'androidPortNumber': 0,
          'deviceName': 'Keys',
          'product': '',
          'driver': 'android.media.midi',
        });
      });

      test('names device, product and driver for the engine', () {
        for (final (description, name, product, driver) in [
          (device(product: 'P'), 'Keys', 'P', 'android.media.midi'),
          (device(name: '', product: 'P'), 'P', 'P', 'android.media.midi'),
          (
            device(
              name: '',
              type: MidiAndroidDeviceDescription.typeVirtual,
              ownService: 'com.example.Service',
            ),
            'MIDI device 5',
            '',
            'com.example.Service',
          ),
        ]) {
          for (final port in mapper.ports(description)) {
            expect(
              [
                port.native[MidiPortRegistry.deviceNameKey],
                port.native[MidiPortRegistry.productKey],
                port.native[MidiPortRegistry.driverKey],
              ],
              [name, product, driver],
            );
          }
        }
      });
    });

    group('device(device)', () {
      test('maps a device of another app', () {
        expect(
          mapper.device(device()),
          MidiDeviceInfo(
            id: const MidiDeviceId('android:5'),
            name: 'Keys',
            manufacturer: 'Acme',
            serialNumber: 'S1',
            transport: MidiTransport.usb,
            driver: 'android.media.midi',
            ports: const [
              MidiPortId('android:5:out:0'),
              MidiPortId('android:5:in:0'),
            ],
          ),
        );
      });

      test('names the service of an own device as driver', () {
        final info = mapper.device(
          device(
            type: MidiAndroidDeviceDescription.typeVirtual,
            ownService: 'com.example.Service',
          ),
        );
        expect(info.driver, 'com.example.Service');
        expect(info.native['androidService'], 'com.example.Service');
      });
    });

    group('driver(device)', () {
      test('names the own service or android.media.midi', () {
        expect(mapper.driver(device()), 'android.media.midi');
        expect(
          mapper.driver(device(ownService: 'com.example.Service')),
          'com.example.Service',
        );
      });
    });

    group('deviceName(device)', () {
      test('takes the name, else the product, else the id', () {
        expect(mapper.deviceName(device(product: 'P')), 'Keys');
        expect(mapper.deviceName(device(name: '', product: 'P')), 'P');
        expect(mapper.deviceName(device(name: '')), 'MIDI device 5');
      });
    });

    group('transport(device)', () {
      test('maps the Android device types', () {
        for (final (type, transport) in [
          (MidiAndroidDeviceDescription.typeUsb, MidiTransport.usb),
          (MidiAndroidDeviceDescription.typeVirtual, MidiTransport.virtual),
          (
            MidiAndroidDeviceDescription.typeBluetooth,
            MidiTransport.bluetoothLe,
          ),
          (99, MidiTransport.unknown),
        ]) {
          expect(mapper.transport(device(type: type)), transport);
        }
      });
    });

    group('protocol(device)', () {
      test('is MIDI 1.0 for byte-stream devices', () {
        expect(mapper.protocol(device()), MidiProtocol.midi1);
      });

      for (final (defaultProtocol, protocol) in [
        (MidiAndroidDeviceDescription.protocolMidi1UpTo64Bits, 'midi1'),
        (MidiAndroidDeviceDescription.protocolMidi1UpTo64BitsAndJrts, 'midi1'),
        (MidiAndroidDeviceDescription.protocolMidi1UpTo128Bits, 'midi1'),
        (MidiAndroidDeviceDescription.protocolMidi1UpTo128BitsAndJrts, 'midi1'),
        (MidiAndroidDeviceDescription.protocolMidi2, 'midi2'),
        (MidiAndroidDeviceDescription.protocolMidi2AndJrts, 'midi2'),
        (MidiAndroidDeviceDescription.protocolUseMidiCi, 'midi2'),
        (MidiAndroidDeviceDescription.protocolUnknown, 'midi2'),
      ]) {
        test('is $protocol for UMP devices with $defaultProtocol', () {
          final ump = device(
            transport: MidiAndroidDeviceDescription.transportUmp,
            defaultProtocol: defaultProtocol,
          );
          expect(mapper.protocol(ump).name, protocol);
        });
      }
    });

    group('capabilities(device, direction)', () {
      test('schedule on USB and Bluetooth outputs only', () {
        for (final (type, own, scheduled) in [
          (MidiAndroidDeviceDescription.typeUsb, false, true),
          (MidiAndroidDeviceDescription.typeBluetooth, false, true),
          (MidiAndroidDeviceDescription.typeVirtual, false, false),
          (MidiAndroidDeviceDescription.typeVirtual, true, false),
        ]) {
          final capabilities = mapper.capabilities(
            device(type: type, ownService: own ? 'S' : null),
            MidiDirection.output,
          );
          expect(capabilities.scheduledSend, scheduled);
          expect(capabilities.cancelPending, scheduled);
          expect(capabilities.timestampsIn, isFalse);
        }
      });

      test('give inputs timestamps', () {
        expect(
          mapper.capabilities(device(), MidiDirection.input),
          const MidiPortCapabilities(timestampsIn: true),
        );
      });

      test('carry SysEx8 on UMP ports with 128-bit packets', () {
        for (final (defaultProtocol, sysEx8) in [
          (MidiAndroidDeviceDescription.protocolMidi1UpTo64Bits, false),
          (MidiAndroidDeviceDescription.protocolMidi1UpTo64BitsAndJrts, false),
          (MidiAndroidDeviceDescription.protocolMidi1UpTo128Bits, true),
          (MidiAndroidDeviceDescription.protocolMidi2, true),
        ]) {
          final capabilities = mapper.capabilities(
            device(
              transport: MidiAndroidDeviceDescription.transportUmp,
              defaultProtocol: defaultProtocol,
            ),
            MidiDirection.input,
          );
          expect(capabilities.ump, isTrue);
          expect(capabilities.sysEx8, sysEx8);
        }
      });
    });

    group('backend', () {
      test('prefixes the ids', () {
        const custom = MidiAndroidPortMapper(backend: 'test');
        expect(custom.backend, 'test');
        expect(custom.deviceId(device()).value, 'test:5');
      });
    });
  });
}
