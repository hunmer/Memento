import 'package:flutter/material.dart';

class TagManagerDialogLocalizations {
  static const String editGroup = '编辑分组';

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'editGroup': 'Edit Group',
    },
    'zh': {
      'editGroup': '编辑分组',
    },
  };

  static String getEditGroup(BuildContext context) {
    return _localizedValues[Localizations.localeOf(context).languageCode]?['editGroup'] ?? editGroup;
  }
}