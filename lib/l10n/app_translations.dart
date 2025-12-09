import 'dart:ui';
import 'package:get/get.dart';
import 'app_translations_en.dart';
import 'app_translations_zh.dart';

/// GetX Translations for app-level internationalization
///
/// This replaces the flutter_localizations system with GetX Translations.
/// All translation keys are prefixed with 'app_' to avoid conflicts.
///
/// Usage:
/// ```dart
/// Text('app_appTitle'.tr)
/// Text('app_completed'.trParams({'percentage': '75'}))
/// ```
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': appTranslationsEn,
        'zh': appTranslationsZh,
      };

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  /// Fallback locale
  static const Locale fallbackLocale = Locale('en');
}
