import 'package:flutter/material.dart';
import 'base_settings_controller.dart';
import 'export_controller.dart';
import 'import_controller.dart';
import 'full_backup_controller.dart';

class SettingsScreenController extends ChangeNotifier {
  final BuildContext context;
  final BaseSettingsController _baseController;
  final ExportController _exportController;
  final ImportController _importController;
  final FullBackupController _fullBackupController;

  SettingsScreenController(this.context)
    : _baseController = BaseSettingsController(context),
      _exportController = ExportController(context),
      _importController = ImportController(context),
      _fullBackupController = FullBackupController(context);

  // 主题相关
  bool get isDarkMode => _baseController.isDarkMode;
  Future<void> initTheme() => _baseController.initTheme();
  Future<void> toggleTheme() => _baseController.toggleTheme();

  // 语言相关
  Locale get currentLocale => _baseController.currentLocale;
  bool get isChineseLocale => _baseController.isChineseLocale;
  Future<void> toggleLanguage() => _baseController.toggleLanguage();

  // 关于对话框
  void showAboutDialog() => _baseController.showAboutDialog();

  // 数据导出
  Future<void> exportData() => _exportController.exportData();

  // 数据导入
  Future<void> importData() => _importController.importData();

  // 全量数据备份与恢复
  Future<void> exportAllData() => _fullBackupController.exportAllData();
  Future<void> importAllData() => _fullBackupController.importAllData();
}
