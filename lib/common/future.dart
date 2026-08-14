import 'dart:async';
import 'dart:ui';

import 'package:fl_clash/common/common.dart';

extension FutureExt<T> on Future<T> {
  Future<T> withTimeout({
    Duration? timeout,
    String? tag,
    VoidCallback? onLast,
    FutureOr<T> Function()? onTimeout,
  }) {
    final realTimeout = timeout ?? const Duration(minutes: 3);
    Timer(realTimeout + commonDuration, () {
      if (onLast != null) {
        onLast();
      }
    });
    return this.timeout(
      realTimeout,
      onTimeout: () async {
        if (onTimeout != null) {
          return onTimeout();
        } else {
          throw TimeoutException('${tag ?? runtimeType} timeout');
        }
      },
    );
  }
}

/// Runs [action] over [items], never with more than [concurrency] in flight.
///
/// Mapping to futures up front and chunking the result does not cap anything:
/// building the list already starts every future.
Future<void> runBatched<T>(
  Iterable<T> items,
  int concurrency,
  Future<void> Function(T item) action,
) async {
  if (concurrency < 1) {
    throw ArgumentError.value(concurrency, 'concurrency', 'must be at least 1');
  }
  final pending = <Future<void>>[];
  for (final item in items) {
    pending.add(action(item));
    if (pending.length == concurrency) {
      await Future.wait(pending);
      pending.clear();
    }
  }
  if (pending.isNotEmpty) {
    await Future.wait(pending);
  }
}

extension CompleterExt<T> on Completer<T> {
  void safeCompleter(T value) {
    if (isCompleted) {
      return;
    }
    complete(value);
  }
}
