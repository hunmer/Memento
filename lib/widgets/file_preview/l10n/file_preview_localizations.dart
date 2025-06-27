import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'file_preview_localizations_en.dart';
import 'file_preview_localizations_zh.dart';

/// 文件预览插件的本地化支持类
abstract class FilePreviewLocalizations {
  FilePreviewLocalizations(String locale) : localeName = locale;

  final String localeName;

  static FilePreviewLocalizations of(BuildContext context) {
    final localizations = Localizations.of<FilePreviewLocalizations>(
      context,
      FilePreviewLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No FilePreviewLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<FilePreviewLocalizations> delegate =
      _FilePreviewLocalizationsDelegate();

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

  // 文件预览插件的本地化字符串
  String get name;
  String get errorFilePreviewFailed;
  String get fileNotAccessible;
  String get fileProcessingFailed;
  String get fileSelectionFailed;
  String get fileSelected;
  String get imageNotExist;
  String get imageProcessingFailed;
  String get imageSelectionFailed;
  String get videoNotSupportedOnWeb;
  String get videoNotExist;
  String get videoProcessingFailed;
  String get videoSelectionFailed;
  String get videoSent;
  String get singleFile;
  String get openFile;
  String get downloadFile;
  String get shareFile;
  String get fileSize;
  String get fileType;
  String get lastModified;
  String get previewNotAvailable;
  String get loadingPreview;
  String get videoLoadFailed;
  String get fileNotExist;

  String get openWithOtherApp;
}

class _FilePreviewLocalizationsDelegate
    extends LocalizationsDelegate<FilePreviewLocalizations> {
  const _FilePreviewLocalizationsDelegate();

  @override
  Future<FilePreviewLocalizations> load(Locale locale) {
    return SynchronousFuture<FilePreviewLocalizations>(
      lookupFilePreviewLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_FilePreviewLocalizationsDelegate old) => false;
}

FilePreviewLocalizations lookupFilePreviewLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return FilePreviewLocalizationsEn();
    case 'zh':
      return FilePreviewLocalizationsZh();
  }

  throw FlutterError(
    'FilePreviewLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
