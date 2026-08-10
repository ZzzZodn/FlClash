import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';

class Migration {
  static Migration? _instance;
  late int _oldVersion;

  Migration._internal();

  final currentVersion = 2;

  factory Migration() {
    _instance ??= Migration._internal();
    return _instance!;
  }

  Future<Config> migrationIfNeeded(
    Map<String, Object?>? configMap, {
    required Future<Config> Function(MigrationData data) sync,
  }) async {
    _oldVersion = await preferences.getVersion();
    if (_oldVersion == currentVersion) {
      try {
        return Config.realFromJson(configMap);
      } catch (_) {
        final isV0 = configMap?['proxiesStyle'] != null;
        if (isV0) {
          _oldVersion = 0;
        } else {
          throw 'Local data is damaged. A reset is required to fix this issue.';
        }
      }
    }
    MigrationData data = MigrationData(configMap: configMap);
    if (_oldVersion == 0 && configMap != null) {
      final clashConfigMap = await preferences.getClashConfigMap();
      if (clashConfigMap != null) {
        configMap['patchClashConfig'] = clashConfigMap;
        await preferences.clearClashConfig();
      }
      data = await _oldToNow(configMap);
    }
    _appendDashboardWidget(data.configMap, DashboardWidget.port);
    final res = await sync(data);
    await preferences.setVersion(currentVersion);
    return res;
  }

  Future<MigrationData> _oldToNow(Map<String, Object?> configMap) async {
    return oldToNowTask(configMap);
  }

  /// Adds a dashboard widget introduced after the stored layout was saved, so
  /// existing users see it without rebuilding their dashboard by hand.
  void _appendDashboardWidget(
    Map<String, Object?>? configMap,
    DashboardWidget widget,
  ) {
    final appSettingProps = configMap?['appSettingProps'];
    if (appSettingProps is! Map) {
      return;
    }
    final dashboardWidgets = appSettingProps['dashboardWidgets'];
    if (dashboardWidgets is! List || dashboardWidgets.contains(widget.name)) {
      return;
    }
    appSettingProps['dashboardWidgets'] = [...dashboardWidgets, widget.name];
  }
}

final migration = Migration();
