// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:test/test.dart';

void main() {
  late _FakeNsd nsd;
  late MidiAndroidServiceAdvertiser advertiser;

  Future<MidiServiceRegistration> register() => advertiser.register(
    name: 'Session',
    type: '_apple-midi._udp',
    port: 5004,
    txt: const {'a': 'b'},
  );

  Matcher nativeError(String api, int code) => throwsA(
    isA<MidiNativeError>()
        .having((e) => e.api, 'api', api)
        .having((e) => e.code, 'code', code),
  );

  setUp(() {
    nsd = _FakeNsd();
    advertiser = MidiAndroidServiceAdvertiser(
      nsd: nsd,
      timeout: const Duration(milliseconds: 50),
    );
  });

  group('MidiAndroidServiceAdvertiser', () {
    group('MidiAndroidServiceAdvertiser({nsd, timeout})', () {
      test('uses NsdManager, which exists on Android only', () {
        expect(
          MidiAndroidServiceAdvertiser.new,
          throwsA(isA<MidiUnsupported>()),
        );
        expect(
          MidiAndroidServiceAdvertiser(nsd: nsd).timeout,
          const Duration(seconds: 10),
        );
      });
    });

    group('register({name, type, port, txt})', () {
      test('completes with the name the registrar chose', () async {
        final registration = register();
        expect(nsd.requests, [
          [
            'Session',
            '_apple-midi._udp',
            5004,
            {'a': 'b'},
          ],
        ]);
        nsd
          ..registered('Session (2)')
          ..registered('ignored');
        expect((await registration).name, 'Session (2)');
      });

      test('throws the NsdManager error of a failure', () async {
        final registration = register();
        nsd
          ..registrationFailed(3)
          ..registrationFailed(4)
          ..registered('ignored');
        await expectLater(
          registration,
          nativeError('NsdManager.registerService', 3),
        );
      });

      test('throws and unregisters after the timeout', () async {
        await expectLater(
          register(),
          nativeError(
            'NsdManager.registerService',
            MidiAndroidErrorCodes.timeout,
          ),
        );
        expect(nsd.unregisters, 1);
      });
    });

    group('MidiServiceRegistration', () {
      group('unregister()', () {
        test('completes when the registrar confirms', () async {
          final registering = register();
          nsd.registered('Session');
          final registration = await registering;
          nsd.unregistered();
          final unregistering = registration.unregister();
          expect(registration.unregister(), same(unregistering));
          nsd
            ..unregistered()
            ..unregistered()
            ..unregistrationFailed(1);
          await unregistering;
          expect(nsd.unregisters, 1);
        });

        test('throws the NsdManager error of a failure', () async {
          final registering = register();
          nsd
            ..registered('Session')
            ..unregistrationFailed(1);
          final registration = await registering;
          final unregistering = registration.unregister();
          nsd
            ..unregistrationFailed(2)
            ..unregistrationFailed(3);
          await expectLater(
            unregistering,
            nativeError('NsdManager.unregisterService', 2),
          );
        });

        test('throws after the timeout', () async {
          final registering = register();
          nsd.registered('Session');
          final registration = await registering;
          await expectLater(
            registration.unregister(),
            nativeError(
              'NsdManager.unregisterService',
              MidiAndroidErrorCodes.timeout,
            ),
          );
        });
      });
    });
  });
}

// #############################################################################
final class _FakeNsd implements MidiAndroidNsd {
  final List<List<Object>> requests = [];
  int unregisters = 0;
  late void Function(String name) registered;
  late void Function(int errorCode) registrationFailed;
  late void Function() unregistered;
  late void Function(int errorCode) unregistrationFailed;

  @override
  void Function() register({
    required String name,
    required String type,
    required int port,
    required Map<String, String> txt,
    required void Function(String name) onRegistered,
    required void Function(int errorCode) onRegistrationFailed,
    required void Function() onUnregistered,
    required void Function(int errorCode) onUnregistrationFailed,
  }) {
    requests.add([name, type, port, txt]);
    registered = onRegistered;
    registrationFailed = onRegistrationFailed;
    unregistered = onUnregistered;
    unregistrationFailed = onUnregistrationFailed;
    return () => unregisters++;
  }
}
