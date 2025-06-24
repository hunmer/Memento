import 'package:flutter/material.dart';

class FloatingBallLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'noRecentPlugin': 'No recently opened plugin found',
      'pageRefreshed': 'Page refreshed',
      'floatingBallSettings': 'Floating Ball Settings',
      'enableFloatingBall': 'Enable Floating Ball',
      'small': 'Small',
      'large': 'Large',
      'positionReset': 'Floating ball position has been reset',
      'resetPosition': 'Reset Floating Ball Position',
      'notSet': 'Not set',
      'noAction': 'No action',
      'backupOptions': 'Backup Options',
      'selectBackupMethod': 'Please select backup method',
      'exportAppData': 'Export App Data',
      'fullBackup': 'Full Backup',
      'webdavSync': 'WebDAV Sync',
    },
    'zh': {
      'noRecentPlugin': '没有找到最近打开的插件',
      'pageRefreshed': '页面已刷新',
      'floatingBallSettings': '悬浮球设置',
      'enableFloatingBall': '启用悬浮球',
      'small': '小',
      'large': '大',
      'positionReset': '悬浮球位置已重置',
      'resetPosition': '重置悬浮球位置',
      'notSet': '未设置',
      'noAction': '无动作',
      'backupOptions': '备份选项',
      'selectBackupMethod': '请选择备份方式',
      'exportAppData': '导出应用数据',
      'fullBackup': '完整备份',
      'webdavSync': 'WebDAV同步',
    },
  };

  static String getText(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return _localizedValues[locale]?[key] ?? _localizedValues['en']![key]!;
  }
}
