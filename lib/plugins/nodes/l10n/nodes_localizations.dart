import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'nodes_localizations_en.dart';
import 'nodes_localizations_zh.dart';

/// Nodes插件的本地化支持类
abstract class NodesLocalizations {
  NodesLocalizations(String locale) : localeName = locale;

  final String localeName;

  static NodesLocalizations of(BuildContext context) {
    final localizations = Localizations.of<NodesLocalizations>(
      context,
      NodesLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No NodesLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<NodesLocalizations> delegate =
      _NodesLocalizationsDelegate();

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

  String get addNotebook;

  // Nodes插件的本地化字符串
  String get name;
  String get nodesSettings;
  String get notebooksCount;
  String get nodesCount;
  String get pendingNodesCount;
  String get deleteNotebookConfirmation;
  String get deleteNodeConfirmation;
  String get createNew;
  String get newFolder;
  String get newNote;
  String get delete;
  String get selectCurrentFolder;
  String get moveTo;
  String get deleteNote;
  String get deleteNoteConfirmation;
  String get movedTo;

  String get addNode;

  String get customFields;

  String get addCustomField;

  String get startDate;

  String get endDate;

  get status;

  String get none;

  String get todo;

  String get doing;

  String get done;

  get key;

  get value;

  String get cancel;

  String get save;

  String get tags;

  String get editNode;

  get nodeTitle;

  String get notes;

  String get copyToText;

  String get clearNodes;

  String get noNodesYet;

  String get copiedToClipboard;

  String get clearNodesTitle;

  String get clearNodesConfirm;

  String get nodesCleared;

  String get clear;

  String get notebooks;

  String get deleteNotebook;

  get nodes;

  get notebookTitle;

  String get editNotebook;

  String get deleteNode;

  String get addChildNode;

  String get addSiblingNode;
}

class _NodesLocalizationsDelegate
    extends LocalizationsDelegate<NodesLocalizations> {
  const _NodesLocalizationsDelegate();

  @override
  Future<NodesLocalizations> load(Locale locale) {
    return SynchronousFuture<NodesLocalizations>(
      lookupNodesLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_NodesLocalizationsDelegate old) => false;
}

NodesLocalizations lookupNodesLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return NodesLocalizationsEn();
    case 'zh':
      return NodesLocalizationsZh();
  }

  throw FlutterError(
    'NodesLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
