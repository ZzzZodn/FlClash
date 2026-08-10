import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common.dart';

/// Test url input shown above a proxy group's proxies.
///
/// The value follows the visible tab: it falls back to the group's own url and
/// then to the global test url, and anything typed here is kept for that group
/// only.
class GroupTestUrlBar extends ConsumerStatefulWidget {
  final Group group;

  const GroupTestUrlBar({super.key, required this.group});

  @override
  ConsumerState<GroupTestUrlBar> createState() => _GroupTestUrlBarState();
}

class _GroupTestUrlBarState extends ConsumerState<GroupTestUrlBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late String _testUrl;
  bool _isTesting = false;

  String get _groupName => widget.group.name;

  String _getTestUrl(String defaultTestUrl) {
    return widget.group.testUrl.takeFirstValid([defaultTestUrl]);
  }

  /// Re-reads the url in effect for this group, including any change applied in
  /// the current frame.
  String _readTestUrl() {
    final defaultTestUrl = ref.read(appSettingProvider).testUrl;
    final group = ref.read(effectiveGroupsProvider).getGroup(_groupName);
    return (group?.testUrl).takeFirstValid([defaultTestUrl]);
  }

  @override
  void initState() {
    super.initState();
    _testUrl = _getTestUrl(ref.read(appSettingProvider).testUrl);
    _controller = TextEditingController(text: _testUrl);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      return;
    }
    if (!_handleSave(silence: true, onlyWhenEdited: true)) {
      _controller.text = _testUrl;
    }
  }

  /// Stores the typed url for this group. Returns false when the input cannot
  /// be used, leaving the stored value untouched.
  ///
  /// Leaving the field or running a test must not turn the url already in
  /// effect into a custom one, otherwise the group would be pinned to it even
  /// after the profile changes its own url.
  bool _handleSave({bool silence = false, bool onlyWhenEdited = false}) {
    final value = _controller.text.trim();
    if (onlyWhenEdited && value == _testUrl) {
      return true;
    }
    if (value.isNotEmpty && !value.isUrl) {
      if (!silence) {
        final appLocalizations = context.appLocalizations;
        context.showNotifier(appLocalizations.urlTip(appLocalizations.testUrl));
      }
      return false;
    }
    final changed = ref
        .read(groupTestUrlsProvider.notifier)
        .setTestUrl(_groupName, value);
    if (changed) {
      // Groups are sorted by delay against their test url, so re-sort them.
      ref.read(proxiesActionProvider.notifier).updateGroupsDebounce();
      _testUrl = _readTestUrl();
      // Only when clearing the input, so typing is never interrupted.
      if (_controller.text != _testUrl) {
        _controller.text = _testUrl;
      }
    }
    return true;
  }

  void _handleReset() {
    _controller.clear();
    _handleSave();
  }

  Future<void> _handleDelayTest() async {
    if (_isTesting || !_handleSave(onlyWhenEdited: true)) {
      return;
    }
    final testUrl = _readTestUrl();
    setState(() {
      _isTesting = true;
    });
    try {
      await delayTest(widget.group.all, testUrl);
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Widget _buildDelayTestButton() {
    return IconButton.filledTonal(
      tooltip: context.appLocalizations.delayTest,
      onPressed: _isTesting ? null : _handleDelayTest,
      icon: _isTesting
          ? SizedBox.square(
              dimension: globalState.measure.bodyMediumHeight,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.network_ping),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final defaultTestUrl = ref.watch(
      appSettingProvider.select((state) => state.testUrl),
    );
    final hasCustomTestUrl = ref.watch(
      groupTestUrlsProvider.select((state) => state[_groupName] != null),
    );
    final testUrl = _getTestUrl(defaultTestUrl);
    if (testUrl != _testUrl) {
      _testUrl = testUrl;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) {
          _controller.text = testUrl;
        }
      });
    }
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 1,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              inputFormatters: TextInputLimits.limit(TextInputLimits.url),
              style: context.textTheme.bodyMedium,
              onSubmitted: (_) {
                _handleSave();
              },
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                hintText: appLocalizations.testUrl,
                prefixIcon: const Icon(Icons.link, size: 20),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: hasCustomTestUrl
                    ? IconButton(
                        tooltip: appLocalizations.reset,
                        onPressed: _handleReset,
                        icon: const Icon(Icons.restore, size: 20),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          _buildDelayTestButton(),
        ],
      ),
    );
  }
}
