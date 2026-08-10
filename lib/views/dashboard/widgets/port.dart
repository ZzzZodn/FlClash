import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/port_dialog.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PortInfo extends StatelessWidget {
  const PortInfo({super.key});

  Future<void> _handleShowPortDialog() async {
    await globalState.showCommonDialog(child: const PortDialog());
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(
          label: appLocalizations.port,
          iconData: Icons.adjust_outlined,
        ),
        onPressed: _handleShowPortDialog,
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: globalState.measure.bodyMediumHeight + 2,
                child: Consumer(
                  builder: (_, ref, _) {
                    final mixedPort = ref.watch(
                      patchClashConfigProvider.select((state) => state.mixedPort),
                    );
                    return FadeThroughBox(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$mixedPort',
                        key: ValueKey(mixedPort),
                        style: context.textTheme.bodyMedium?.toLight
                            .adjustSize(1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
