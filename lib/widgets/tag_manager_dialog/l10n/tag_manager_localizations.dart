import 'package:flutter/material.dart';

class TagManagerLocalizations {
  static const String newGroup = '新建分组';
  static const String cancel = '取消';
  static const String confirm = '确定';
  static const String newTag = '新建标签';
  static const String deleteGroup = '删除分组';
  static const String clearSelected = '清空 \$selectedCount 选中';

  static Map<String, Map<String, String>> translations = {
    'en': {
      'newGroup': 'New Group',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'newTag': 'New Tag',
      'deleteGroup': 'Delete Group',
      'clearSelected': 'Clear \$selectedCount selected',
    },
    'zh': {
      'newGroup': '新建分组',
      'cancel': '取消',
      'confirm': '确定',
      'newTag': '新建标签',
      'deleteGroup': '删除分组',
      'clearSelected': '清空 \$selectedCount 选中',
    },
  };

  static String of(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return translations[locale]?[key] ?? translations['en']![key]!;
  }
}