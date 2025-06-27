import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'image_picker_localizations_en.dart';
import 'image_picker_localizations_zh.dart';

/// 图片选择器的本地化支持类
abstract class ImagePickerLocalizations {
  ImagePickerLocalizations(String locale) : localeName = locale;

  final String localeName;

  static ImagePickerLocalizations? of(BuildContext context) {
    return Localizations.of<ImagePickerLocalizations>(
      context,
      ImagePickerLocalizations,
    );
  }

  static const LocalizationsDelegate<ImagePickerLocalizations> delegate =
      _ImagePickerLocalizationsDelegate();

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

  // 图片选择器的本地化字符串
  String get name;
  String get takePhoto;
  String get chooseFromGallery;
  String get cancel;
  String get permissionDenied;
  String get permissionDeniedMessage;
  String get settings;
  String get noCameraAvailable;
  String get photoCaptureFailed;
  String get imageSelectionFailed;
  String get imageProcessingFailed;
  String get maxImagesReached;
  String get deleteImage;
  String get confirmDeleteImage;
  String get selectMultipleImages;
  String get selectImage;
  String get selectFromGallery;
  String get selectImageFailed;
  String get takePhotoFailed;
  String get cropImage;
  String get saveCroppedImageFailed;
  String get cropFailed;
}

class _ImagePickerLocalizationsDelegate
    extends LocalizationsDelegate<ImagePickerLocalizations> {
  const _ImagePickerLocalizationsDelegate();

  @override
  Future<ImagePickerLocalizations> load(Locale locale) {
    return SynchronousFuture<ImagePickerLocalizations>(
      lookupImagePickerLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ImagePickerLocalizationsDelegate old) => false;
}

ImagePickerLocalizations lookupImagePickerLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return ImagePickerLocalizationsEn(locale.languageCode);
    case 'zh':
      return ImagePickerLocalizationsZh(locale.languageCode);
  }

  throw FlutterError(
    'ImagePickerLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
