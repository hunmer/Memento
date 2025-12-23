import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/theme_controller.dart';
import 'package:Memento/core/builtin_plugins.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/services/clipboard_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_settings_controller.dart';
import 'export_controller.dart';
import 'import_controller.dart';
import 'full_backup_controller.dart';
import 'webdav_sync_controller.dart';
import 'auto_update_controller.dart';
import 'package:Memento/widgets/backup_time_picker.dart';

class SettingsScreenController extends ChangeNotifier {
  final BaseSettingsController _baseController;
  late ExportController _exportController;
  late ImportController _importController;
  late FullBackupController _fullBackupController;
  late WebDAVSyncController _webdavSyncController;
  late AutoUpdateController _autoUpdateController;
  late SharedPreferences _prefs;
  BackupSchedule? _backupSchedule;
  DateTime? _lastBackupCheckDate;
  BuildContext? _context;
  bool _initialized = false;
  final Map<String, bool> _pluginEnabledStates = {};

  bool isInitialized() => _initialized;

  SettingsScreenController() : _baseController = BaseSettingsController();

  Future<void> initializeControllers(BuildContext context) async {
    _context = context;
    await initPrefs(); // 确保等待初始化完成
    _exportController = ExportController(context);
    _importController = ImportController(context);
    _fullBackupController = FullBackupController(context);
    _webdavSyncController = WebDAVSyncController(context);
    _autoUpdateController = AutoUpdateController(context);
    await _loadPluginStates();
    _initialized = true;
    notifyListeners();
  }

  Future<void> initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadBackupSchedule();
    await _loadLastBackupCheckDate();
    enableLogging = _prefs.getBool('enable_logging') ?? false;
    _locationApiKey = _prefs.getString('location_api_key') ?? 'dad6a772bf826842c3049e9c7198115c';

    // 加载剪切板自动读取配置（默认关闭）
    _clipboardAutoRead = _prefs.getBool('clipboard_auto_read') ?? false;
    ClipboardService.instance.autoReadEnabled = _clipboardAutoRead;
  }

  Future<void> _loadBackupSchedule() async {
    final type = _prefs.getInt('backup_schedule_type');
    if (type != null) {
      _backupSchedule = BackupSchedule(
        type: BackupScheduleType.values[type],
        date:
            _prefs.getString('backup_date') != null
                ? DateTime.parse(_prefs.getString('backup_date')!)
                : null,
        time:
            _prefs.getString('backup_time') != null
                ? TimeOfDay(
                  hour: int.parse(
                    _prefs.getString('backup_time')!.split(':')[0],
                  ),
                  minute: int.parse(
                    _prefs.getString('backup_time')!.split(':')[1],
                  ),
                )
                : null,
        days:
            _prefs.getStringList('backup_days')?.map(int.parse).toList() ?? [],
        monthDays:
            _prefs
                .getStringList('backup_month_days')
                ?.map(int.parse)
                .toList() ??
            [],
      );
    } else {
      // 设置默认备份计划 - 每天凌晨2点备份
      _backupSchedule = BackupSchedule(
        type: BackupScheduleType.daily,
        time: TimeOfDay(hour: 2, minute: 0),
      );
      await setBackupSchedule(_backupSchedule!);
    }
  }

  Future<void> _loadLastBackupCheckDate() async {
    final dateStr = _prefs.getString('last_backup_check_date');
    if (dateStr != null) {
      _lastBackupCheckDate = DateTime.parse(dateStr);
    }
  }

  void toggleTheme(context) => ThemeController.toggleTheme(context);

  /// 直接设置主题，避免 toggleThemeMode 在三种模式间循环导致需要点击两次
  void setTheme(BuildContext context, bool isDark) {
    if (isDark) {
      ThemeController.setDarkTheme(context);
    } else {
      ThemeController.setLightTheme(context);
    }
  }

  // 语言相关
  Future<void> toggleLanguage(context) async {
    await _baseController.showLanguageSelectionDialog(context);
  }

  // 数据导出
  Future<void> exportData([BuildContext? context]) =>
      _exportController.exportData(context ?? _context);

  // 数据导入
  Future<void> importData() => _importController.importData();

  // 全量数据备份与恢复
  Future<void> exportAllData() => _fullBackupController.exportAllData();
  Future<void> importAllData() => _fullBackupController.importAllData();

  // WebDAV同步相关
  bool get isWebDAVConnected => _webdavSyncController.isConnected;
  Future<bool> uploadAllToWebDAV() => _webdavSyncController.uploadAllToWebDAV();
  Future<bool> downloadAllFromWebDAV() =>
      _webdavSyncController.downloadAllFromWebDAV();

  // 自动打开最后使用的插件设置
  bool get autoOpenLastPlugin => globalPluginManager.autoOpenLastPlugin;
  set autoOpenLastPlugin(bool value) {
    globalPluginManager.autoOpenLastPlugin = value;
    notifyListeners();
  }

  // 自动更新相关
  bool get autoCheckUpdate => _autoUpdateController.autoCheckUpdate;
  set autoCheckUpdate(bool value) {
    _autoUpdateController.autoCheckUpdate = value;
  }

  bool _enableLogging = false;
  bool get enableLogging => _enableLogging;
  set enableLogging(bool value) {
    _enableLogging = value;
    _prefs.setBool('enable_logging', value);
    notifyListeners();
  }

  // 定位 API Key 设置
  String _locationApiKey = 'dad6a772bf826842c3049e9c7198115c';
  String get locationApiKey => _locationApiKey;
  Future<void> setLocationApiKey(String value) async {
    _locationApiKey = value;
    await _prefs.setString('location_api_key', value);
    notifyListeners();
  }

  // 剪切板配置
  bool _clipboardAutoRead = false;
  bool get clipboardAutoRead => _clipboardAutoRead;
  set clipboardAutoRead(bool value) {
    _clipboardAutoRead = value;
    ClipboardService.instance.autoReadEnabled = value;
    _prefs.setBool('clipboard_auto_read', value);
    notifyListeners();
  }

  /// 手动读取并识别剪切板
  Future<bool> readAndProcessClipboard() async {
    return await ClipboardService.instance.processClipboard();
  }

  Future<void> checkForUpdates() => _autoUpdateController.showUpdateDialog();

  List<PluginBase> get availablePlugins {
    final installed = globalPluginManager.allPlugins;
    final installedIds = installed.map((plugin) => plugin.id).toSet();
    final builtin = BuiltinPlugins.createAll();
    final additional =
        builtin.where((plugin) => !installedIds.contains(plugin.id)).toList();
    return [...installed, ...additional];
  }

  bool isPluginEnabled(String pluginId) {
    return _pluginEnabledStates[pluginId] ?? true;
  }

  Future<void> setPluginEnabled(String pluginId, bool enabled) async {
    _pluginEnabledStates[pluginId] = enabled;
    notifyListeners();
    await globalConfigManager.setPluginEnabledState(pluginId, enabled);
  }

  Future<void> _loadPluginStates() async {
    final storedStates = globalConfigManager.getPluginEnabledStates();
    _pluginEnabledStates
      ..clear()
      ..addAll(storedStates);

    final Set<String> knownPluginIds = {};
    for (final plugin in globalPluginManager.allPlugins) {
      knownPluginIds.add(plugin.id);
    }
    for (final plugin in BuiltinPlugins.createAll()) {
      knownPluginIds.add(plugin.id);
    }
    for (final pluginId in knownPluginIds) {
      _pluginEnabledStates.putIfAbsent(pluginId, () => true);
    }
  }

  // 备份相关方法
  Future<void> setBackupSchedule(BackupSchedule schedule) async {
    _backupSchedule = schedule;
    await _prefs.setInt('backup_schedule_type', schedule.type.index);
    if (schedule.date != null) {
      await _prefs.setString('backup_date', schedule.date!.toIso8601String());
    }
    if (schedule.time != null) {
      await _prefs.setString(
        'backup_time',
        '${schedule.time!.hour}:${schedule.time!.minute}',
      );
    }
    await _prefs.setStringList(
      'backup_days',
      schedule.days.map((e) => e.toString()).toList(),
    );
    await _prefs.setStringList(
      'backup_month_days',
      schedule.monthDays.map((e) => e.toString()).toList(),
    );

    // 设置计划时不立即备份，只更新最后检查时间为现在
    await resetBackupCheckDate();
    notifyListeners();
  }

  Future<bool> shouldPerformBackup() async {
    if (_backupSchedule == null) return false;
    if (_lastBackupCheckDate == null) {
      await resetBackupCheckDate(); // 首次设置时初始化检查时间
      return false;
    }

    final now = DateTime.now();
    final lastCheck = _lastBackupCheckDate!;

    switch (_backupSchedule!.type) {
      case BackupScheduleType.specificDate:
        // 只在指定日期当天检查
        return now.year == _backupSchedule!.date!.year &&
            now.month == _backupSchedule!.date!.month &&
            now.day == _backupSchedule!.date!.day &&
            now.isAfter(lastCheck);
      case BackupScheduleType.daily:
        // 每天检查，且时间已过设定的时间点
        final scheduledTime =
            _backupSchedule!.time ?? TimeOfDay(hour: 0, minute: 0);
        final scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );
        return now.isAfter(scheduledDateTime) &&
            now.difference(lastCheck).inDays >= 1;
      case BackupScheduleType.weekly:
        // 每周指定日检查，且时间已过设定的时间点
        final currentDay = now.weekday;
        final scheduledTime =
            _backupSchedule!.time ?? TimeOfDay(hour: 0, minute: 0);
        final scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );
        return _backupSchedule!.days.contains(currentDay) &&
            now.isAfter(scheduledDateTime) &&
            now.difference(lastCheck).inDays >= 1;
      case BackupScheduleType.monthly:
        // 每月指定日检查，且时间已过设定的时间点
        final currentDay = now.day;
        final scheduledTime =
            _backupSchedule!.time ?? TimeOfDay(hour: 0, minute: 0);
        final scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );
        return _backupSchedule!.monthDays.contains(currentDay) &&
            now.isAfter(scheduledDateTime) &&
            now.difference(lastCheck).inDays >= 1;
    }
  }

  Future<void> resetBackupCheckDate() async {
    _lastBackupCheckDate = DateTime.now();
    await _prefs.setString(
      'last_backup_check_date',
      _lastBackupCheckDate!.toIso8601String(),
    );
    notifyListeners();
  }

  // 获取当前备份计划
  BackupSchedule? get backupSchedule => _backupSchedule;
}
