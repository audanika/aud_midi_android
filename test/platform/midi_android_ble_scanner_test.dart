// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_android/aud_midi_android.dart';
import 'package:test/test.dart';

void main() {
  group('MidiAndroidBleScanner', () {
    group('start({onResult, onFailed}), stop(), isEnabled', () {
      test('form the contract of a scanner', () {
        final MidiAndroidBleScanner scanner = _Scanner();
        final results = <String>[];
        scanner.start(
          onResult: (result) => results.add(result.address),
          onFailed: (code) => results.add('failed $code'),
        );
        scanner.stop();
        expect(scanner.isEnabled, isTrue);
        expect(results, ['AA', 'failed 1']);
      });
    });
  });
}

// #############################################################################
final class _Scanner implements MidiAndroidBleScanner {
  void Function(int errorCode)? _onFailed;

  @override
  bool get isEnabled => true;

  @override
  void start({
    required void Function(MidiAndroidBleScanResult result) onResult,
    required void Function(int errorCode) onFailed,
  }) {
    _onFailed = onFailed;
    onResult(const MidiAndroidBleScanResult(address: 'AA'));
  }

  @override
  void stop() => _onFailed?.call(1);
}
