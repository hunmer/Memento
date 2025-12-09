import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  bool isInitialized() => _initialized;

  SettingsScreenController() : _baseController = BaseSettingsController() {
    initPrefs();
  }

  void initializeControllers(BuildContext context) {
    _context = context;
    _exportController = ExportController(context);
    _importController = ImportController(context);
    _fullBackupController = FullBackupController(context);
    _webdavSyncController = WebDAVSyncController(context);
    _autoUpdateController = AutoUpdateController(context);
    _initialized = true;
    notifyListeners();
  }

  Future<void> initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadBackupSchedule();
    await _loadLastBackupCheckDate();
    enableLogging = _prefs.getBool('enable_logging') ?? false;
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

  Future<void> checkForUpdates() => _autoUpdateController.showUpdateDialog();

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
