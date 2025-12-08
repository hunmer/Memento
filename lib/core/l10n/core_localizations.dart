import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'core_localizations_zh.dart';
import 'core_localizations_en.dart';

/// 核心模块国际化代理
class CoreLocalizationsDelegate extends LocalizationsDelegate<CoreLocalizations> {
  const CoreLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<CoreLocalizations> load(Locale locale) {
    return SynchronousFuture<CoreLocalizations>(
      _getLocalizedValues(locale),
    );
  }

  @override
  bool shouldReload(LocalizationsDelegate<CoreLocalizations> old) => false;

  CoreLocalizations _getLocalizedValues(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return CoreLocalizationsEn();
      case 'zh':
      default:
        return CoreLocalizationsZh();
    }
  }
}

/// 核心模块国际化接口
abstract class CoreLocalizations {
  // Application Startup
  String get starting;

  // Action Executor
  String get inputJavaScriptCode;
  String get cancel;
  String get execute;

  // Custom Action Examples
  String get save;
  String get executionResult;
  String executionStatus(bool success);
  String get outputData;
  String get errorMessage;
  String get close;
  String get inputFloatingBallJavaScriptCode;

  // Migration Tool
  String get configMigration;
  String get migrating;
  String get startMigration;

  // Action Config Form
  String get notSelected;
  String get selectColor;
  String get iconSelectorNotImplemented;

  // Action Group Editor
  String get sequentialExecution;
  String get parallelExecution;
  String get conditionalExecution;
  String get executeAllActions;
  String get executeAnyAction;
  String get executeFirstOnly;
  String get executeLastOnly;
  String get addAction;
  String get edit;
  String get moveUp;
  String get moveDown;
  String get delete;

  // Action Selector Dialog
  String get clearSettings;
  String get confirm;

  // Floating Button Manager
  String get confirmDelete;
  String confirmDeleteButton(String title);
  String get floatingButtonManager;
  String get addFirstButton;

  // Floating Button Edit Dialog
  String get clearIconImage;
  String confirmClearIconImage();
  String get clear;
  String get selectIcon;

  // Plugin Overlay Widget
  String get routeError;
  String routeNotFound(String routeName);

  // Create Action Group
  String get createActionGroup;

  static CoreLocalizations? of(BuildContext context) {
    return Localizations.of<CoreLocalizations>(context, CoreLocalizations);
  }
}
