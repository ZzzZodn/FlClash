import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

double get listHeaderHeight {
  final measure = globalState.measure;
  return 20 + measure.titleMediumHeight + 4 + measure.bodyMediumHeight + 2;
}

double getItemHeight(ProxyCardType proxyCardType) {
  final measure = globalState.measure;
  final baseHeight =
      16 + measure.bodyMediumHeight * 2 + measure.bodySmallHeight + 8 + 4;
  return switch (proxyCardType) {
    ProxyCardType.expand => baseHeight + measure.labelSmallHeight + 6,
    ProxyCardType.shrink => baseHeight,
    ProxyCardType.min => baseHeight - measure.bodyMediumHeight,
  };
}

List<Group> getCurrentGroups() {
  return globalState.container.read(currentGroupsStateProvider).value;
}

List<Group> getGroups() {
  return globalState.container.read(effectiveGroupsProvider);
}

String? getCurrentGroupName() {
  return globalState.container.read(
    currentProfileProvider.select((state) => state?.currentGroupName),
  );
}

void updateCurrentGroupName(String groupName) {
  globalState.container
      .read(proxiesActionProvider.notifier)
      .updateCurrentGroupName(groupName);
}

void updateCurrentUnfoldSet(Set<String> value) {
  globalState.container
      .read(proxiesActionProvider.notifier)
      .updateCurrentUnfoldSet(value);
}

Future<Delay?> proxyDelayTest(Proxy proxy, [String? testUrl]) async {
  final ref = globalState.container;
  final groups = getGroups();
  final selectedMap = ref.read(
    currentProfileProvider.select((state) => state?.selectedMap ?? {}),
  );
  final state = computeRealSelectedProxyState(
    proxy.name,
    groups: groups,
    selectedMap: selectedMap,
  );
  final currentTestUrl = state.testUrl.takeFirstValid([
    ref.read(realTestUrlProvider(testUrl)),
  ]);
  if (state.proxyName.isEmpty) {
    return null;
  }
  final action = ref.read(proxiesActionProvider.notifier);
  action.setDelay(Delay(url: currentTestUrl, name: state.proxyName, value: 0));
  final delay = await coreController.getDelay(currentTestUrl, state.proxyName);
  action.setDelay(delay);
  return delay;
}

/// Testing every proxy at once floods dns and the handshake path, so the first
/// run reports timeouts that a second run does not.
const _delayTestConcurrency = 100;

Future<void> delayTest(List<Proxy> proxies, [String? testUrl]) async {
  final total = Stopwatch()..start();
  var reachable = 0;
  var timedOut = 0;
  var slowestRoundTrip = 0;
  await runBatched(proxies, _delayTestConcurrency, (proxy) async {
    final roundTrip = Stopwatch()..start();
    final delay = await proxyDelayTest(proxy, testUrl);
    roundTrip.stop();
    if (delay == null) {
      return;
    }
    if (roundTrip.elapsedMilliseconds > slowestRoundTrip) {
      slowestRoundTrip = roundTrip.elapsedMilliseconds;
    }
    (delay.value ?? 0) > 0 ? reachable++ : timedOut++;
  });
  total.stop();
  // Surfaced in the logs page. A round trip near the core's own 5s budget
  // means the connection itself never completed; one near the 6s ceiling the
  // app applies means no answer came back at all.
  commonPrint.log(
    'delay test: ${proxies.length} proxies, concurrency $_delayTestConcurrency, '
    'reachable $reachable, timeout $timedOut, '
    'slowest round trip ${slowestRoundTrip}ms, total ${total.elapsedMilliseconds}ms',
  );
  globalState.container.read(sortNumProvider.notifier).add();
}

double getScrollToSelectedOffset({
  required String groupName,
  required List<Proxy> proxies,
}) {
  final ref = globalState.container;
  final columns = ref.read(proxiesColumnsProvider);
  final proxyCardType = ref.read(
    proxiesStyleSettingProvider.select((state) => state.cardType),
  );
  final selectedProxyName = ref.read(selectedProxyNameProvider(groupName));
  final findSelectedIndex = proxies.indexWhere(
    (proxy) => proxy.name == selectedProxyName,
  );
  final selectedIndex = findSelectedIndex != -1 ? findSelectedIndex : 0;
  final rows = (selectedIndex / columns).floor();
  return rows * getItemHeight(proxyCardType) + (rows - 1) * 8;
}
