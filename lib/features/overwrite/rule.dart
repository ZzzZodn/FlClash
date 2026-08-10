library;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:fl_clash/models/state.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ruleItemHeight = globalState.measure.bodyMediumHeight + 26;

/// Column widths shared by [RuleListHeader] and [RuleItem] so the rows line up
/// as a table: match type, what it matches on, where it routes to.
const _actionFlex = 4;
const _contentFlex = 7;
const _targetFlex = 4;

/// Search bar for a rule list: a keyword box plus the column it searches.
///
/// Searching by policy turns the box into a filtering dropdown, so the
/// policies in use can be completed while typing or picked from the arrow.
class RuleSearchBar extends ConsumerStatefulWidget {
  final List<String> targets;

  const RuleSearchBar({super.key, required this.targets});

  @override
  ConsumerState<RuleSearchBar> createState() => _RuleSearchBarState();
}

class _RuleSearchBarState extends ConsumerState<RuleSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(queryProvider(QueryTag.rules)),
    );
    _controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged() {
    ref.read(queryProvider(QueryTag.rules).notifier).value = _controller.text;
  }

  void _handleFieldChanged(RuleQueryField? field) {
    if (field == null) {
      return;
    }
    ref.read(ruleQueryFieldStateProvider.notifier).value = field;
    // The keyword rarely carries over between columns, so start clean.
    _controller.clear();
  }

  String _fieldLabel(RuleQueryField field) {
    final appLocalizations = context.appLocalizations;
    return switch (field) {
      RuleQueryField.content => appLocalizations.content,
      RuleQueryField.target => appLocalizations.splitStrategy,
    };
  }

  InputDecorationTheme get _inputTheme {
    return InputDecorationTheme(
      isDense: true,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _buildKeywordField(RuleQueryField field) {
    final appLocalizations = context.appLocalizations;
    if (field == RuleQueryField.target) {
      return DropdownMenu<String>(
        controller: _controller,
        enableFilter: true,
        requestFocusOnTap: true,
        expandedInsets: EdgeInsets.zero,
        menuHeight: 320,
        hintText: appLocalizations.search,
        inputDecorationTheme: _inputTheme,
        leadingIcon: const Icon(Icons.search, size: 20),
        dropdownMenuEntries: [
          for (final target in widget.targets)
            DropdownMenuEntry(value: target, label: target),
        ],
      );
    }
    return TextField(
      controller: _controller,
      maxLines: 1,
      textInputAction: TextInputAction.search,
      inputFormatters: TextInputLimits.limit(TextInputLimits.search),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        hintText: appLocalizations.search,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _controller.clear,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = ref.watch(ruleQueryFieldStateProvider);
    ref.watch(queryProvider(QueryTag.rules));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 8,
        children: [
          Expanded(flex: 3, child: _buildKeywordField(field)),
          SizedBox(
            width: 148,
            child: DropdownMenu<RuleQueryField>(
              initialSelection: field,
              expandedInsets: EdgeInsets.zero,
              requestFocusOnTap: false,
              inputDecorationTheme: _inputTheme,
              onSelected: _handleFieldChanged,
              dropdownMenuEntries: [
                for (final item in RuleQueryField.values)
                  DropdownMenuEntry(value: item, label: _fieldLabel(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Frames a rule section, so the added rules and the profile's own rules read
/// as two separate blocks rather than one long run of rows.
class RuleSectionBox extends StatelessWidget {
  final List<Widget> slivers;

  const RuleSectionBox({super.key, required this.slivers});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: DecoratedSliver(
        decoration: ShapeDecoration(
          color: context.colorScheme.surfaceContainerLow.opacity60,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: context.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ...slivers,
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }
}

/// Title above a rule list, set apart from the rules themselves.
class RuleSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const RuleSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: globalState.measure.titleMediumHeight,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.titleMedium?.toBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions.isNotEmpty) ...[const SizedBox(width: 8), ...actions],
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4),
              child: Text(
                subtitle!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.opacity80,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Column titles for a list of [RuleItem]s.
class RuleListHeader extends StatelessWidget {
  const RuleListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final style = context.textTheme.labelSmall?.toBold.copyWith(
      color: context.colorScheme.primary,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 4,
            bottom: 6,
          ),
          child: Row(
            children: [
              Expanded(
                flex: _actionFlex,
                child: Text(
                  appLocalizations.proxyType,
                  style: style,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: _contentFlex,
                child: Text(
                  appLocalizations.content,
                  style: style,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: _targetFlex,
                child: Text(
                  appLocalizations.splitStrategy,
                  style: style,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
          child: Divider(
            height: 1,
            thickness: 1,
            color: context.colorScheme.primary.opacity30,
          ),
        ),
      ],
    );
  }
}

class RuleItem extends StatelessWidget {
  final bool isSelected;
  final bool isEditing;
  final Rule rule;
  final bool hasMatch;
  final void Function()? onSelected;
  final void Function(Rule rule)? onEdit;
  final bool Function(Rule rule)? checkInvalidHandler;

  const RuleItem({
    super.key,
    required this.isSelected,
    required this.rule,
    required this.onSelected,
    required this.onEdit,
    this.checkInvalidHandler,
    this.isEditing = false,
    this.hasMatch = false,
  });

  /// Shows a rule that comes from the profile itself, so it can be read but
  /// not selected or edited.
  const RuleItem.readonly({super.key, required this.rule})
    : isSelected = false,
      isEditing = false,
      hasMatch = true,
      onSelected = null,
      onEdit = null,
      checkInvalidHandler = _alwaysValid;

  static bool _alwaysValid(Rule rule) => false;

  VM2<bool, Color?> _checkInvalid(BuildContext context) {
    if (rule.ruleAction != RuleAction.SUB_RULE) {
      final ruleTarget = rule.ruleTarget ?? '';
      if (ruleTarget.toUpperCase() == 'DIRECT') {
        return VM2(
          false,
          Colors.green.harmonizeWith(context.colorScheme.primary),
        );
      } else if (ruleTarget.toUpperCase() == 'REJECT') {
        return VM2(
          false,
          Colors.orange.harmonizeWith(context.colorScheme.primary),
        );
      } else if (hasMatch && ruleTarget.toUpperCase() == 'MATCH') {
        return VM2(false, context.colorScheme.tertiary);
      }
    }
    bool invalid = true;
    if (checkInvalidHandler != null) {
      invalid = checkInvalidHandler!(rule);
    }
    return VM2(
      invalid,
      invalid ? context.colorScheme.error : context.colorScheme.tertiary,
    );
  }

  Widget _buildInfoWidget(BuildContext context) {
    return CommonMinIconButtonTheme(
      child: IconButton(
        onPressed: () {
          globalState.showMessage(
            message: TextSpan(
              text: rule.targetErrorTip(
                context.appLocalizations.invalidSubRule(rule.subRule ?? ''),
                context.appLocalizations.invalidPolicy(rule.ruleTarget ?? ''),
              ),
            ),
          );
        },
        icon: Icon(Icons.info, size: 16.ap, color: context.colorScheme.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm2 = _checkInvalid(context);
    final invalid = vm2.a;
    final title = _buildTitle(context, vm2);
    if (onEdit == null) {
      return DecorationListItem(
        minVerticalPadding: 0,
        horizontalTitleGap: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: title,
      );
    }
    return SelectedDecorationListItem(
      minVerticalPadding: 0,
      isSelected: isSelected,
      isEditing: isEditing,
      horizontalTitleGap: 0,
      invalid: invalid,
      onSelected: () {
        onSelected!();
      },
      title: title,
      onPressed: () {
        onEdit!(rule);
      },
    );
  }

  Widget _buildTitle(BuildContext context, VM2<bool, Color?> vm2) {
    final invalid = vm2.a;
    return Center(
      child: Builder(
        builder: (context) {
          final style = DefaultTextStyle.of(context).style.toJetBrainsMono
              .copyWith(fontSize: context.textTheme.bodyMedium?.fontSize);
          return Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: _actionFlex,
                child: TooltipText(
                  text: Text(
                    rule.ruleAction.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: _contentFlex,
                child: TooltipText(
                  text: Text(
                    rule.realContent ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style.copyWith(color: style.color?.opacity60),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: _targetFlex,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (invalid) _buildInfoWidget(context),
                    Flexible(
                      child: TooltipText(
                        text: Text(
                          rule.realTarget ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: style.copyWith(color: vm2.b),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RuleStatusItem extends StatelessWidget {
  final bool status;
  final Rule rule;
  final void Function(bool) onChange;

  const RuleStatusItem({
    super.key,
    required this.status,
    required this.rule,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return DecorationListItem(
      title: TooltipText(
        text: Text(
          rule.rawValue,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.toJetBrainsMono,
        ),
      ),
      trailing: Switch(value: status, onChanged: onChange),
      onPressed: () {
        onChange(!status);
      },
    );
  }
}

class AddOrEditRuleDialog extends StatefulWidget {
  final Rule? rule;

  const AddOrEditRuleDialog({super.key, this.rule});

  @override
  State<AddOrEditRuleDialog> createState() => _AddOrEditRuleDialogState();
}

class _AddOrEditRuleDialogState extends State<AddOrEditRuleDialog> {
  late RuleAction _ruleAction;
  final _ruleTargetController = TextEditingController();
  final _contentController = TextEditingController();
  bool _noResolve = false;
  bool _src = false;
  List<DropdownMenuEntry> _targetItems = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _initState();
    super.initState();
  }

  void _initState() {
    _targetItems = [
      ...RuleTarget.values.map(
        (item) => DropdownMenuEntry(value: item.name, label: item.name),
      ),
      const DropdownMenuEntry(value: 'MATCH', label: 'MATCH'),
    ];
    final rule = widget.rule;
    if (rule != null) {
      _ruleAction = rule.ruleAction;
      _contentController.text = rule.content ?? '';
      _ruleTargetController.text = rule.ruleTarget ?? '';
      _noResolve = rule.noResolve;
      _src = rule.src;
      return;
    }
    _ruleAction = RuleAction.addedRuleActions.first;
    if (_targetItems.isNotEmpty) {
      _ruleTargetController.text = _targetItems.first.value;
    }
  }

  @override
  void didUpdateWidget(AddOrEditRuleDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule != widget.rule) {
      _initState();
    }
  }

  void _handleSubmit() {
    final res = _formKey.currentState?.validate();
    if (res == false) {
      return;
    }
    final rule = Rule(
      id: widget.rule?.id ?? snowflake.id,
      ruleAction: _ruleAction,
      content: _contentController.text,
      ruleTarget: _ruleTargetController.text,
      noResolve: _noResolve,
      src: _src,
    );
    Navigator.of(context).pop(rule);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonDialog(
      title: widget.rule != null
          ? appLocalizations.editRule
          : appLocalizations.addRule,
      actions: [
        TextButton(
          onPressed: _handleSubmit,
          child: Text(appLocalizations.confirm),
        ),
      ],
      child: DropdownMenuTheme(
        data: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            border: const OutlineInputBorder(),
            labelStyle: context.textTheme.bodyLarge?.copyWith(
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (_, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.tonal(
                    onPressed: () async {
                      _ruleAction =
                          await globalState.showCommonDialog<RuleAction>(
                            filter: false,
                            child: OptionsDialog<RuleAction>(
                              title: appLocalizations.ruleName,
                              options: RuleAction.addedRuleActions,
                              textBuilder: (item) => item.value,
                              value: _ruleAction,
                            ),
                          ) ??
                          _ruleAction;
                      setState(() {});
                    },
                    child: Text(_ruleAction.value),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    keyboardType: TextInputType.text,
                    inputFormatters: TextInputLimits.limit(
                      TextInputLimits.rule,
                    ),
                    onFieldSubmitted: (_) {
                      _handleSubmit();
                    },
                    controller: _contentController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: appLocalizations.content,
                    ),
                    validator: (_) {
                      if (_contentController.text.isEmpty) {
                        return appLocalizations.emptyTip(
                          appLocalizations.content,
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FormField<String>(
                    validator: (_) {
                      if (_ruleTargetController.text.isEmpty) {
                        return appLocalizations.emptyTip(
                          appLocalizations.ruleTarget,
                        );
                      }
                      return null;
                    },
                    builder: (filed) {
                      return DropdownMenu(
                        controller: _ruleTargetController,
                        label: Text(appLocalizations.ruleTarget),
                        width: 200,
                        menuHeight: 250,
                        enableFilter: false,
                        enableSearch: false,
                        dropdownMenuEntries: _targetItems,
                        errorText: filed.errorText,
                      );
                    },
                  ),
                  if (_ruleAction.hasParams) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      children: [
                        CommonCard(
                          radius: 8,
                          isSelected: _src,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Text(
                              appLocalizations.sourceIp,
                              style: context.textTheme.bodyMedium,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _src = !_src;
                            });
                          },
                        ),
                        CommonCard(
                          radius: 8,
                          isSelected: _noResolve,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Text(
                              appLocalizations.noResolve,
                              style: context.textTheme.bodyMedium,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _noResolve = !_noResolve;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
