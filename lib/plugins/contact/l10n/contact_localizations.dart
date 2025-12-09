import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'contact_localizations_en.dart';
import 'contact_localizations_zh.dart';

/// 联系人插件的本地化支持类
abstract class ContactLocalizations {
  ContactLocalizations(String locale) : localeName = locale;

  final String localeName;

  static ContactLocalizations of(BuildContext context) {
    final localizations = Localizations.of<ContactLocalizations>(
      context,
      ContactLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No ContactLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<ContactLocalizations> delegate =
      _ContactLocalizationsDelegate();

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

  // 联系人插件的本地化字符串
  String get name;
  String get username;
  String get contactList;
  String get newContact;
  String get editContact;
  String get deleteContact;
  String get phone;
  String get email;
  String get address;
  String get notes;
  String get save;
  String get cancel;
  String get deleteConfirmation;
  String get noContacts;
  String get searchContacts;
  String get contactGroups;
  String get addGroup;
  String get editGroup;
  String get deleteGroup;
  String get groupName;
  String get selectGroup;
  String get importContacts;
  String get exportContacts;
  String get shareContact;
  String get contactDetails;
  String get favoriteContacts;
  String get addToFavorites;
  String get removeFromFavorites;
  String get call;
  String get message;
  String get emailContact;
  String get share;
  String get contactNotFound;

  String get totalContacts;

  String get recentContacts;

  String get sortBy;

  String get createdTime;

  String get lastContactTime;

  String get contactCount;

  String get addContact;

  get saveFailedMessage;

  String get formValidationMessage;

  String get confirmDelete;

  String get deleteConfirmMessage;

  String get contacts;

  String get errorMessage;

  String get addTag;

  String get addCustomField;

  String get saveFirstMessage;

  get basicInfoTab;

  get recordsTab;

  String get upload;

  get nameLabel;

  get nameRequiredError;

  get phoneLabel;

  get addressLabel;

  get notesLabel;

  get addTagTooltip;

  get addCustomFieldTooltip;

  get deleteFieldTooltip;

  String get selectContactTitle;

  get searchContactsHint;

  String get filter;

  get nameKeyword;

  String get dateRange;

  String get startDate;

  String get endDate;

  get uncontactedDays;

  get noLimit;

  get days;

  get tags;

  get reset;

  // 交互记录表单
  String get addInteractionRecord;
  String get editInteractionRecord;
  String get dateLabel;
  String get timeLabel;
  String get notesHint;
  String get otherParticipants;
//... (existing code)
  String get addParticipantTooltip;

  String get organizationLabel;
  String get emailLabel;
  String get websiteLabel;
  String get done;

  // 添加的字符串
  String get separator;
  String get customFields;
  String get customActivityEvents;
  String get addCustomEvent;
  String get pickColor;
}

class _ContactLocalizationsDelegate
//... (rest of the file)
    extends LocalizationsDelegate<ContactLocalizations> {
  const _ContactLocalizationsDelegate();

  @override
  Future<ContactLocalizations> load(Locale locale) {
    return SynchronousFuture<ContactLocalizations>(
      lookupContactLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ContactLocalizationsDelegate old) => false;
}

ContactLocalizations lookupContactLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return ContactLocalizationsEn();
    case 'zh':
      return ContactLocalizationsZh();
  }

  throw FlutterError(
    'ContactLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
