import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/profiles/overwrite/custom/rules.dart';
import 'package:fl_clash/views/profiles/overwrite/standard.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shortcut to a profile's rule list, reachable straight from the profile menu
/// instead of walking more -> override -> rules.
///
/// The list follows the profile's override mode so the rules shown here are the
/// ones the profile actually applies.
class ProfileRulesView extends ConsumerWidget {
  final int profileId;

  const ProfileRulesView(this.profileId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overwriteType = ref.watch(overwriteTypeProvider(profileId));
    return _ApplyProfileOnDispose(
      child: switch (overwriteType) {
        OverwriteType.custom => CustomRulesView(profileId),
        OverwriteType.standard || OverwriteType.script => ProfileIdProvider(
          profileId: profileId,
          child: CommonScaffold(
            title: context.appLocalizations.rule,
            body: const CustomScrollView(slivers: [StandardContent()]),
          ),
        ),
      },
    );
  }
}

class _ApplyProfileOnDispose extends StatefulWidget {
  final Widget child;

  const _ApplyProfileOnDispose({required this.child});

  @override
  State<_ApplyProfileOnDispose> createState() => _ApplyProfileOnDisposeState();
}

class _ApplyProfileOnDisposeState extends State<_ApplyProfileOnDispose> {
  @override
  void dispose() {
    super.dispose();
    globalState.container.read(setupActionProvider.notifier).autoApplyProfile();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
