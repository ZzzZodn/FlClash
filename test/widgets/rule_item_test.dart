import 'package:fl_clash/common/measure.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/overwrite/rule.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _rule = Rule(
  id: 1,
  ruleAction: RuleAction.DOMAIN_SUFFIX,
  content: 'example.com',
  ruleTarget: 'Proxy',
);

void main() {
  testWidgets('RuleItem.readonly shows the match and its target', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _TestApp(
          child: Scaffold(body: RuleItem.readonly(rule: _rule)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOMAIN_SUFFIX'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
    expect(find.text('Proxy'), findsOneWidget);
  });

  testWidgets('RuleItem.readonly cannot be selected or edited', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _TestApp(
          child: Scaffold(body: RuleItem.readonly(rule: _rule)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The editable variant carries a selection checkbox; the read-only one
    // must not, and a target it cannot resolve must not read as an error.
    expect(find.byType(CommonCheckBox), findsNothing);
    expect(find.byIcon(Icons.info), findsNothing);
  });

  testWidgets('RuleItem stays selectable when callbacks are given', (
    tester,
  ) async {
    var edited = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: _TestApp(
          child: Scaffold(
            body: RuleItem(
              isSelected: false,
              rule: _rule,
              onSelected: () {},
              onEdit: (_) => edited++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CommonCheckBox), findsOneWidget);

    await tester.tap(find.text('example.com'));
    await tester.pumpAndSettle();

    expect(edited, 1);
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
