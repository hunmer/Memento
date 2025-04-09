import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'chat_localizations_en.dart';
import 'chat_localizations_zh.dart';

/// 聊天插件的本地化支持类
abstract class ChatLocalizations {
  ChatLocalizations(String locale) : localeName = locale;

  final String localeName;

  static ChatLocalizations? of(BuildContext context) {
    return Localizations.of<ChatLocalizations>(context, ChatLocalizations);
  }

  static const LocalizationsDelegate<ChatLocalizations> delegate = _ChatLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  // 聊天插件的本地化字符串
  String get chatPluginName;
  String get chatPluginDescription;
  String get showAvatarInChannelList;
  String get channelList;
  String get newChannel;
  String get deleteChannel;
  String get deleteMessages;
  String get draft;
  String get chatRoom;
  String get enterMessage;
  String get justNow;
  String get edit;
  String get copy;
  String get delete;
  String get pin;
  String get clear;
  String get info;
  String get multiSelectMode;
  String get clearMessages;
  String get channelInfo;
  String get selectedMessages;
  String get edited;
  
  String minutesAgo(int minutes);
  String hoursAgo(int hours);
  String daysAgo(int days);
  String userInitial(String username);
  String get today;
  String get yesterday;
}

class _ChatLocalizationsDelegate extends LocalizationsDelegate<ChatLocalizations> {
  const _ChatLocalizationsDelegate();

  @override
  Future<ChatLocalizations> load(Locale locale) {
    return SynchronousFuture<ChatLocalizations>(lookupChatLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ChatLocalizationsDelegate old) => false;
}

ChatLocalizations lookupChatLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en': return ChatLocalizationsEn();
    case 'zh': return ChatLocalizationsZh();
  }

  throw FlutterError(
    'ChatLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.'
  );
}