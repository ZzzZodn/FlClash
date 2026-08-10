import 'package:fl_clash/common/measure.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/test_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _globalTestUrl = 'https://global.test/generate_204';
const _groupTestUrl = 'https://group.test/generate_204';
const _customTestUrl = 'https://custom.test/generate_204';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required Group group,
    Map<String, String> groupTestUrls = const {},
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingProvider.overrideWithBuild(
            (_, _) => const AppSettingProps(testUrl: _globalTestUrl),
          ),
          groupTestUrlsProvider.overrideWithBuild((_, _) => groupTestUrls),
        ],
        child: _TestApp(
          child: Scaffold(body: GroupTestUrlBar(group: group)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('falls back to the global test url', (tester) async {
    await pumpBar(
      tester,
      group: const Group(name: 'Auto', type: GroupType.Selector),
    );

    expect(find.text(_globalTestUrl), findsOneWidget);
  });

  testWidgets('prefers the group own test url', (tester) async {
    await pumpBar(
      tester,
      group: const Group(
        name: 'Auto',
        type: GroupType.URLTest,
        testUrl: _groupTestUrl,
      ),
    );

    expect(find.text(_groupTestUrl), findsOneWidget);
  });

  testWidgets('offers no reset action without a custom test url', (
    tester,
  ) async {
    await pumpBar(
      tester,
      group: const Group(
        name: 'Auto',
        type: GroupType.URLTest,
        testUrl: _groupTestUrl,
      ),
    );

    expect(find.byIcon(Icons.restore), findsNothing);
  });

  testWidgets('shows the custom test url and a reset action', (tester) async {
    // The parent hands over groups that already carry the override.
    await pumpBar(
      tester,
      group: const Group(
        name: 'Auto',
        type: GroupType.URLTest,
        testUrl: _customTestUrl,
      ),
      groupTestUrls: const {'Auto': _customTestUrl},
    );

    expect(find.text(_customTestUrl), findsOneWidget);
    expect(find.byIcon(Icons.restore), findsOneWidget);
  });

  testWidgets('leaving the field untouched stores no custom url', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appSettingProvider.overrideWithBuild(
          (_, _) => const AppSettingProps(testUrl: _globalTestUrl),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          child: Scaffold(
            body: GroupTestUrlBar(
              group: Group(
                name: 'Auto',
                type: GroupType.URLTest,
                testUrl: _groupTestUrl,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // Pinning the group to the url it already uses would survive the profile
    // changing its own url later on.
    expect(container.read(groupTestUrlsProvider), isEmpty);
  });

  testWidgets('reacts to a custom test url being stored', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appSettingProvider.overrideWithBuild(
          (_, _) => const AppSettingProps(testUrl: _globalTestUrl),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          child: Scaffold(
            body: GroupTestUrlBar(
              group: Group(name: 'Auto', type: GroupType.Selector),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.restore), findsNothing);

    container
        .read(groupTestUrlsProvider.notifier)
        .setTestUrl('Auto', _customTestUrl);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.restore), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalState.navigatorKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.delegate.supportedLocales,
      builder: (context, child) {
        globalState.theme = CommonTheme.of(context, 1);
        globalState.measure = Measure.of(context, 1);
        return child!;
      },
      home: child,
    );
  }
}
