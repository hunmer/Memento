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

  static ChatLocalizations of(BuildContext context) {
    final localizations = Localizations.of<ChatLocalizations>(
      context,
      ChatLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No ChatLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<ChatLocalizations> delegate =
      _ChatLocalizationsDelegate();

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

  // 聊天插件的本地化字符串
  String get pluginName;
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
  String get channelsTab;
  String get timelineTab;
  String get timelineComingSoon;
  String get editProfile;

  // Advanced filter related strings
  String get advancedFilter;
  String get searchIn;
  String get channelNames;
  String get usernames;
  String get messageContent;
  String get dateRange;
  String get startDate;
  String get endDate;
  String get clearDates;
  String get selectChannels;
  String get selectUsers;
  String get noChannelsAvailable;
  String get noUsersAvailable;
  String get setBackground;

  // Message options dialog
  String get messageOptions;
  String get addEmoji;
  String get settings;
  String get editMessage;
  String get deleteMessage;
  String get deleteMessageConfirmation;
  String get copiedToClipboard;
  String get createChannelFailed;
  String get noMessagesYet;
  String get noMessagesFound;

  // New strings for chat functionality
  String get copiedSelectedMessages;
  String get aiAssistantNotFound;
  String get aiMessages;
  String get filterAiMessages;
  String get favoriteMessages;
  String get showOnlyFavorites;

  String get recordingFailed;
  String get gotIt;
  String get recordingStopError;
  String get selectDate;
  String get invalidAudioMessage;
  String get fileNotAccessible;
  String get fileProcessingFailed;
  String get fileSelectionFailed;
  String get fileSelected;
  String get imageNotExist;
  String get imageProcessingFailed;
  String get imageSelectionFailed;
  String get clearAllMessages;
  String get confirmClearAllMessages;
  String get videoNotSupportedOnWeb;
  String get videoNotExist;
  String get videoProcessingFailed;
  String get videoSelectionFailed;
  String get videoSent;
  String get videoRecordingFailed;
  String get channelCreationFailed;

  // New strings for the found hardcoded texts
  String get usernameCannotBeEmpty;
  String get updateFailed;
  String get showAll;
  String get singleFile;
  String get contextRange;
  String get setContextRange;
  String get currentRange;
  String get titleCannotBeEmpty;

  @override
  String get deleteChannelConfirmation =>
      'Are you sure you want to delete channel "\${channel.title}"? This action cannot be undone.';
  String get profileTitle;
  String get chatSettings;
  String get showAvatarInChat;
  String get playSoundOnSend;
  String get showAvatarInTimeline;

  String minutesAgo(int minutes);
  String hoursAgo(int hours);
  String daysAgo(int days);
  String userInitial(String username);
  String get today;
  String get yesterday;

  // Message input actions
  String get advancedEditor;
  String get photo;
  String get takePhoto;
  String get recordVideo;
  String get video;
  String get pluginAnalysis;
  String get file;
  String get audioRecording;
  String get smartAgent;
  String get channelCount;
  String get totalMessages;

  String get editMessageTitle;

  get messageHintText;

  String get errorFilePreviewFailed;

  String get audioMessageBubbleErrorText;
}

class _ChatLocalizationsDelegate
    extends LocalizationsDelegate<ChatLocalizations> {
  const _ChatLocalizationsDelegate();

  @override
  Future<ChatLocalizations> load(Locale locale) {
    return SynchronousFuture<ChatLocalizations>(
      lookupChatLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ChatLocalizationsDelegate old) => false;
}

ChatLocalizations lookupChatLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en':
      return ChatLocalizationsEn();
    case 'zh':
      return ChatLocalizationsZh();
  }

  throw FlutterError(
    'ChatLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
