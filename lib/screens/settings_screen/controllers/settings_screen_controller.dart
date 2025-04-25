import 'package:flutter/material.dart';
import 'package:Memento/main.dart';
import 'base_settings_controller.dart';
import 'export_controller.dart';
import 'import_controller.dart';
import 'full_backup_controller.dart';
import 'webdav_sync_controller.dart';

class SettingsScreenController extends ChangeNotifier {
  final BuildContext context;
  final BaseSettingsController _baseController;
  final ExportController _exportController;
  final ImportController _importController;
  final FullBackupController _fullBackupController;
  final WebDAVSyncController _webdavSyncController;

  SettingsScreenController(this.context)
    : _baseController = BaseSettingsController(context),
      _exportController = ExportController(context),
      _importController = ImportController(context),
      _fullBackupController = FullBackupController(context),
      _webdavSyncController = WebDAVSyncController(context);

  // 主题相关
  bool get isDarkMode => _baseController.isDarkMode;
  Future<void> initTheme() => _baseController.initTheme();
  Future<void> toggleTheme() => _baseController.toggleTheme();

  // 语言相关
  Locale get currentLocale => _baseController.currentLocale;
  bool get isChineseLocale => _baseController.isChineseLocale;
  Future<void> toggleLanguage() => _baseController.toggleLanguage();

  // 数据导出
  Future<void> exportData() => _exportController.exportData();

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
}
