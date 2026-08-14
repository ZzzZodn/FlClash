import 'dart:async';

import 'package:fl_clash/common/future.dart';
import 'package:test/test.dart';

class _ConcurrencyProbe {
  int inFlight = 0;
  int peak = 0;
  final completed = <int>[];

  Future<void> call(int item) async {
    inFlight++;
    if (inFlight > peak) {
      peak = inFlight;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
    inFlight--;
    completed.add(item);
  }
}

void main() {
  group('runBatched', () {
    test('never exceeds the requested concurrency', () async {
      final probe = _ConcurrencyProbe();
      await runBatched(List.generate(330, (i) => i), 100, probe.call);

      expect(probe.peak, lessThanOrEqualTo(100));
      expect(probe.completed, hasLength(330));
    });

    test('actually runs in parallel up to the limit', () async {
      final probe = _ConcurrencyProbe();
      await runBatched(List.generate(20, (i) => i), 10, probe.call);

      // A serial implementation would peak at 1.
      expect(probe.peak, 10);
    });

    test('runs everything when there are fewer items than the limit', () async {
      final probe = _ConcurrencyProbe();
      await runBatched([1, 2, 3], 100, probe.call);

      expect(probe.completed, hasLength(3));
      expect(probe.peak, 3);
    });

    test('handles an empty input', () async {
      final probe = _ConcurrencyProbe();
      await runBatched(<int>[], 10, probe.call);

      expect(probe.completed, isEmpty);
    });

    test('rejects a concurrency below one', () {
      expect(
        () => runBatched([1], 0, (_) async {}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
