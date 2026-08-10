import 'package:fl_clash/common/measure.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PortInfo shows the current mixed port', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patchClashConfigProvider.overrideWithBuild(
            (_, _) => const PatchClashConfig(mixedPort: 7899),
          ),
        ],
        child: const _TestApp(
          child: Scaffold(body: SizedBox(width: 200, child: PortInfo())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7899'), findsOneWidget);
  });

  testWidgets('PortInfo follows port changes', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          child: Scaffold(body: SizedBox(width: 200, child: PortInfo())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith(mixedPort: 1080));
    await tester.pumpAndSettle();

    expect(find.text('1080'), findsOneWidget);
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
