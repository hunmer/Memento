import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'scripts_center_localizations_en.dart';
import 'scripts_center_localizations_zh.dart';

/// 脚本中心插件的本地化支持类
abstract class ScriptsCenterLocalizations {
  ScriptsCenterLocalizations(String locale) : localeName = locale;

  final String localeName;

  static ScriptsCenterLocalizations of(BuildContext context) {
    final localizations = Localizations.of<ScriptsCenterLocalizations>(
      context,
      ScriptsCenterLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No ScriptsCenterLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<ScriptsCenterLocalizations> delegate =
      _ScriptsCenterLocalizationsDelegate();

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

  // 插件基本信息
  String get name;
  String get scriptCenter;

  // 脚本编辑
  String get format;
  String get addTrigger;
  String get addTriggerCondition;
  String get add;
  String categoryLabel(String category);
  String descriptionLabel(String description);
  String delayLabel(int delay);

  // 脚本类型
  String get moduleType;
  String get standaloneType;

  // 输入参数
  String get addInputParameter;
  String get enableScript;
  String get requiredParameter;
  String get userMustFillThisParameter;
  String get thisParameterIsOptional;

  // 操作按钮
  String get cancel;
  String get run;

  // 其他
  String get all;
}

class _ScriptsCenterLocalizationsDelegate
    extends LocalizationsDelegate<ScriptsCenterLocalizations> {
  const _ScriptsCenterLocalizationsDelegate();

  @override
  Future<ScriptsCenterLocalizations> load(Locale locale) {
    return SynchronousFuture<ScriptsCenterLocalizations>(
      lookupScriptsCenterLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ScriptsCenterLocalizationsDelegate old) => false;
}

ScriptsCenterLocalizations lookupScriptsCenterLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en':
      return ScriptsCenterLocalizationsEn();
    case 'zh':
      return ScriptsCenterLocalizationsZh();
  }

  throw FlutterError(
    'ScriptsCenterLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations setup. Please ensure that the locale is supported.',
  );
}