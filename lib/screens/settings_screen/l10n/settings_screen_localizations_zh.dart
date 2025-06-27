import 'package:Memento/screens/settings_screen/l10n/settings_screen_localizations.dart';

class SettingsScreenLocalizationsZh extends SettingsScreenLocalizations {
  SettingsScreenLocalizationsZh() : super('zh');

  @override
  String get settingsTitle => '设置';

  @override
  String get languageTitle => '语言 (中文)';

  @override
  String get languageSubtitle => '点击切换到英文';

  @override
  String get darkModeTitle => '深色模式';

  @override
  String get darkModeSubtitle => '切换应用主题';

  @override
  String get exportDataTitle => '导出应用数据';

  @override
  String get exportDataSubtitle => '将插件数据导出到文件';

  @override
  String get dataManagementTitle => '数据文件管理';

  @override
  String get dataManagementSubtitle => '管理应用数据目录中的文件';

  @override
  String get importDataTitle => '导入应用数据';

  @override
  String get importDataSubtitle => '从文件导入插件数据';

  @override
  String get fullBackupTitle => '完整备份';

  @override
  String get fullBackupSubtitle => '备份整个应用数据目录';

  @override
  String get fullRestoreTitle => '完整恢复';

  @override
  String get fullRestoreSubtitle => '从备份恢复整个应用数据（覆盖现有数据）';

  @override
  String get webDAVTitle => 'WebDAV 同步';

  @override
  String get webDAVConnected => '已连接';

  @override
  String get webDAVDisconnected => '未连接';

  @override
  String get floatingBallTitle => '悬浮球设置';

  @override
  String get floatingBallEnabled => '已启用';

  @override
  String get floatingBallDisabled => '已禁用';

  @override
  String get autoBackupTitle => '自动备份设置';

  @override
  String get autoBackupSubtitle => '设置自动备份计划';

  @override
  String get autoOpenLastPluginTitle => '自动打开上次使用的插件';

  @override
  String get autoOpenLastPluginSubtitle => '启动时自动打开最后使用的插件';

  @override
  String get autoCheckUpdateTitle => '自动检查更新';

  @override
  String get autoCheckUpdateSubtitle => '定期检查应用新版本';

  @override
  String get checkUpdateTitle => '检查更新';

  @override
  String get checkUpdateSubtitle => '立即检查应用新版本';

  @override
  String get logSettingsTitle => '日志设置';

  @override
  String get logSettingsSubtitle => '配置日志记录选项';

  @override
  String get updateAvailableTitle => '发现新版本';

  @override
  String get updateAvailableContent =>
      '当前版本: {currentVersion}\n最新版本: {latestVersion}\n更新内容:';

  @override
  String get updateLaterButton => '稍后再说';

  @override
  String get updateViewButton => '查看更新';

  @override
  String get alreadyLatestVersion => '当前已是最新版本';

  @override
  String get updateCheckFailed => '检查更新失败: {error}';

  @override
  String get checkingForUpdates => '正在检查更新...';
}
