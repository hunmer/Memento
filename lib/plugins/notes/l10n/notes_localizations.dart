import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'notes_localizations_en.dart';
import 'notes_localizations_zh.dart';

/// 笔记插件的本地化支持类
abstract class NotesLocalizations {
  NotesLocalizations(String locale) : localeName = locale;

  final String localeName;

  static NotesLocalizations of(BuildContext context) {
    final localizations = Localizations.of<NotesLocalizations>(
      context,
      NotesLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No NotesLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<NotesLocalizations> delegate =
      _NotesLocalizationsDelegate();

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
  String get notesPluginDescription;

  // 统计信息
  String get totalNotes;
  String get recentNotes;

  // 文件夹和笔记操作
  String get newNote;
  String get newFolder;
  String get editNote;
  String get moveNote;
  String get deleteNote;
  String get deleteNoteConfirm;
  String get renameFolder;
  String get deleteFolder;
  String get deleteFolderConfirm;
  String get emptyFolder;

  // 搜索
  String get searchHint;
  String get search;
  String get noSearchResults;

  // 列表标题
  String get folders;
  String get notes;

  // 按钮文本
  String get cancel;
  String get confirm;
  String get edit;
  String get delete;
  String get moveTo;

  // 输入提示
  String get folderNameHint;

  // 新增文本
  String get createNew;
  String get movedTo;
  String get filter;
  String get tags;
  String get dateRange;
  String get clearAll;
  String get apply;
  String get typeToSearch;
  String get noResultsFound;

  String get movedToFolder;
  String get selectSubfolder;

  // 文件夹选择
  String get selectFolder;
  String get selectTag;
  String noTagsAvailable(String tagType);
  String get allTags;
}

class _NotesLocalizationsDelegate
    extends LocalizationsDelegate<NotesLocalizations> {
  const _NotesLocalizationsDelegate();

  @override
  Future<NotesLocalizations> load(Locale locale) {
    return SynchronousFuture<NotesLocalizations>(
      lookupNotesLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_NotesLocalizationsDelegate old) => false;
}

NotesLocalizations lookupNotesLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en':
      return NotesLocalizationsEn();
    case 'zh':
      return NotesLocalizationsZh();
  }

  throw FlutterError(
    'NotesLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations setup. Please ensure that the locale is supported.',
  );
}
