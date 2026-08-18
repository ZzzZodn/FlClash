import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/manager/core_manager.dart';
import 'package:fl_clash/manager/status_manager.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCoreHandlerInterface extends Mock implements CoreHandlerInterface {}

/// Mounts [CoreManager] the way the app does, with [StatusManager] above the
/// navigator so `globalState.showNotifier` can reach it.
Future<ProviderContainer> _pumpCoreManager(WidgetTester tester) async {
  final coreInterface = _MockCoreHandlerInterface();
  when(() => coreInterface.stopLog()).thenAnswer((_) {});
  final controller = CoreController.test(coreInterface);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: globalState.navigatorKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.delegate.supportedLocales,
        builder: (_, child) => StatusManager(
          child: CoreManager(controller: controller, child: child!),
        ),
        home: const SizedBox(),
      ),
    ),
  );
  return container;
}

Future<void> _sendGeoUpdate(
  WidgetTester tester, {
  required bool updating,
  bool skipped = false,
  String? error,
}) async {
  coreEventManager.sendEvent(
    CoreEvent(
      type: CoreEventType.geoUpdate,
      data: <String, dynamic>{
        'type': 'ASN',
        'updating': updating,
        'skipped': skipped,
        'error': error,
      },
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('duplicate crash events disconnect the core only once', (
    tester,
  ) async {
    final coreInterface = _MockCoreHandlerInterface();
    when(() => coreInterface.stopLog()).thenAnswer((_) {});
    final controller = CoreController.test(coreInterface);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CoreManager(controller: controller, child: const SizedBox()),
        ),
      ),
    );
    container.read(coreStatusProvider.notifier).value = CoreStatus.connected;
    final transitions = <CoreStatus>[];
    final subscription = container.listen<CoreStatus>(
      coreStatusProvider,
      (_, next) => transitions.add(next),
    );
    addTearDown(subscription.close);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    const crash = CoreEvent(type: CoreEventType.crash, data: 'boom');
    coreEventManager.sendEvent(crash);
    coreEventManager.sendEvent(crash);
    await tester.pump();

    expect(container.read(coreStatusProvider), CoreStatus.disconnected);
    expect(transitions, [CoreStatus.disconnected]);
    verifyNever(() => coreInterface.stop());

    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  group('geo update notifications', () {
    testWidgets('an automatic update runs without announcing itself', (
      tester,
    ) async {
      final container = await _pumpCoreManager(tester);
      // The provider is auto-disposed, so hold it to observe what the manager
      // wrote rather than a freshly built default.
      final subscription = container.listen(
        isUpdatingProvider(GeoResource.ASN.updatingKey),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await _sendGeoUpdate(tester, updating: true);
      expect(find.text('Updating ASN...'), findsNothing);
      expect(
        container.read(isUpdatingProvider(GeoResource.ASN.updatingKey)),
        isTrue,
      );

      await _sendGeoUpdate(tester, updating: false);
      expect(find.text('ASN updated'), findsNothing);
      expect(
        container.read(isUpdatingProvider(GeoResource.ASN.updatingKey)),
        isFalse,
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a failure is reported instead of a success', (tester) async {
      await _pumpCoreManager(tester);

      await _sendGeoUpdate(tester, updating: true);
      await _sendGeoUpdate(
        tester,
        updating: false,
        error: "can't download ASN database file",
      );

      expect(find.text('ASN updated'), findsNothing);
      expect(
        find.text("Could not update ASN: can't download ASN database file"),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an update the user asked for announces that it started', (
      tester,
    ) async {
      final container = await _pumpCoreManager(tester);
      final action = container.read(geoResourceActionProvider.notifier);
      action.markRequested(GeoResource.ASN);

      await _sendGeoUpdate(tester, updating: true);
      expect(find.text('Updating ASN...'), findsOneWidget);
      expect(action.isRequested(GeoResource.ASN), isTrue);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an update the user asked for reports its result', (
      tester,
    ) async {
      final container = await _pumpCoreManager(tester);
      final action = container.read(geoResourceActionProvider.notifier);
      action.markRequested(GeoResource.ASN);

      await _sendGeoUpdate(tester, updating: false);

      expect(find.text('ASN updated'), findsOneWidget);
      // Consumed, so the automatic rounds that follow stay quiet again.
      expect(action.isRequested(GeoResource.ASN), isFalse);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
