import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'group_selector_localizations_en.dart';
import 'group_selector_localizations_zh.dart';

abstract class GroupSelectorLocalizations {
  GroupSelectorLocalizations(String locale) : localeName = locale;

  final String localeName;

  static GroupSelectorLocalizations of(BuildContext context) {
    final localizations = Localizations.of<GroupSelectorLocalizations>(
      context,
      GroupSelectorLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No GroupSelectorLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<GroupSelectorLocalizations> delegate =
      _GroupSelectorLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  // 分组选择器本地化字符串
  String get selectGroup;
  String get renameGroup;
  String get groupName;
  String get deleteGroup;
  String get deleteGroupConfirmation;
  String get newGroup;
  String get createGroup;
  String get cancel;
  String get ok;
}

class _GroupSelectorLocalizationsDelegate
    extends LocalizationsDelegate<GroupSelectorLocalizations> {
  const _GroupSelectorLocalizationsDelegate();

  @override
  Future<GroupSelectorLocalizations> load(Locale locale) {
    return SynchronousFuture<GroupSelectorLocalizations>(
      lookupGroupSelectorLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_GroupSelectorLocalizationsDelegate old) => false;
}

GroupSelectorLocalizations lookupGroupSelectorLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return GroupSelectorLocalizationsEn();
    case 'zh':
      return GroupSelectorLocalizationsZh();
  }

  throw FlutterError(
    'GroupSelectorLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}