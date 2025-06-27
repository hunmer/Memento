import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'memento'**
  String get appTitle;

  /// No description provided for @pluginManager.
  ///
  /// In en, this message translates to:
  /// **'Plugin Manager'**
  String get pluginManager;

  /// No description provided for @backupOptions.
  ///
  /// In en, this message translates to:
  /// **'Backup Options'**
  String get backupOptions;

  /// No description provided for @selectBackupMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select backup method'**
  String get selectBackupMethod;

  /// No description provided for @exportAppData.
  ///
  /// In en, this message translates to:
  /// **'Export App Data'**
  String get exportAppData;

  /// No description provided for @fullBackup.
  ///
  /// In en, this message translates to:
  /// **'Full Backup'**
  String get fullBackup;

  /// No description provided for @webdavSync.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Sync'**
  String get webdavSync;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'select Date'**
  String get selectDate;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'show All'**
  String get showAll;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete?'**
  String get confirmDelete;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @adjustCardSize.
  ///
  /// In en, this message translates to:
  /// **'Adjust Card Size'**
  String get adjustCardSize;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @noPluginsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No plugins available'**
  String get noPluginsAvailable;

  /// No description provided for @backupInProgress.
  ///
  /// In en, this message translates to:
  /// **'Backup in progress'**
  String get backupInProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed: {percentage}%'**
  String completed(Object percentage);

  /// No description provided for @exportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get exportCancelled;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @importWarning.
  ///
  /// In en, this message translates to:
  /// **'Import will completely overwrite current app data.\nWe recommend backing up existing data before importing.\n\nContinue?'**
  String get importWarning;

  /// No description provided for @stillContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get stillContinue;

  /// No description provided for @importCancelled.
  ///
  /// In en, this message translates to:
  /// **'Import cancelled'**
  String get importCancelled;

  /// No description provided for @selectBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Please select backup file'**
  String get selectBackupFile;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @importInProgress.
  ///
  /// In en, this message translates to:
  /// **'Import in progress'**
  String get importInProgress;

  /// No description provided for @processingBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Processing backup file...'**
  String get processingBackupFile;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data imported successfully, please restart app'**
  String get importSuccess;

  /// No description provided for @restartRequired.
  ///
  /// In en, this message translates to:
  /// **'Restart required'**
  String get restartRequired;

  /// No description provided for @exportingData.
  ///
  /// In en, this message translates to:
  /// **'exporting Data'**
  String get exportingData;

  /// No description provided for @importingData.
  ///
  /// In en, this message translates to:
  /// **'importing Data'**
  String get importingData;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'please Wait'**
  String get pleaseWait;

  /// No description provided for @restartMessage.
  ///
  /// In en, this message translates to:
  /// **'Data import completed, app restart is required to take effect.'**
  String get restartMessage;

  /// No description provided for @fileSelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'File selection failed: {error}'**
  String fileSelectionFailed(Object error);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @importTimeout.
  ///
  /// In en, this message translates to:
  /// **'Import timeout: file may be too large or inaccessible'**
  String get importTimeout;

  /// No description provided for @filesystemError.
  ///
  /// In en, this message translates to:
  /// **'Filesystem error: unable to read or write file'**
  String get filesystemError;

  /// No description provided for @invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file: file may be corrupted'**
  String get invalidBackupFile;

  /// No description provided for @dataExportedTo.
  ///
  /// In en, this message translates to:
  /// **'Data exported to: {path}'**
  String dataExportedTo(Object path);

  /// No description provided for @exportFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailedWithError(Object error);

  /// No description provided for @noPluginDataFound.
  ///
  /// In en, this message translates to:
  /// **'No plugin data found for import'**
  String get noPluginDataFound;

  /// No description provided for @importFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailedWithError(Object error);

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'{permission} permission required'**
  String permissionRequired(Object permission);

  /// No description provided for @permissionRequiredForApp.
  ///
  /// In en, this message translates to:
  /// **'App requires {permission} permission to work properly. Grant permission?'**
  String permissionRequiredForApp(Object permission);

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get grantPermission;

  /// No description provided for @permissionRequiredInSettings.
  ///
  /// In en, this message translates to:
  /// **'{permission} permission is required to continue. Please grant permission in system settings.'**
  String permissionRequiredInSettings(Object permission);

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to continue. Please grant permission in system settings.'**
  String get storagePermissionRequired;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get downloadCancelled;

  /// No description provided for @moveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Move successful'**
  String get moveSuccess;

  /// No description provided for @moveFailed.
  ///
  /// In en, this message translates to:
  /// **'Move failed: {error}'**
  String moveFailed(Object error);

  /// No description provided for @renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed: {error}'**
  String renameFailed(Object error);

  /// No description provided for @exportSuccessTo.
  ///
  /// In en, this message translates to:
  /// **'Export successful to: {path}'**
  String exportSuccessTo(Object path);

  /// No description provided for @selectFolderToImport.
  ///
  /// In en, this message translates to:
  /// **'Select folder to import'**
  String get selectFolderToImport;

  /// No description provided for @selectPluginToExport.
  ///
  /// In en, this message translates to:
  /// **'Select plugin to export'**
  String get selectPluginToExport;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select image'**
  String get selectImage;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from gallery'**
  String get selectFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @testForegroundTask.
  ///
  /// In en, this message translates to:
  /// **'Test Foreground Task'**
  String get testForegroundTask;

  /// No description provided for @failedToLoadPlugins.
  ///
  /// In en, this message translates to:
  /// **'Failed to load plugins: {error}'**
  String failedToLoadPlugins(Object error);

  /// No description provided for @setBackupSchedule.
  ///
  /// In en, this message translates to:
  /// **'Set backup schedule'**
  String get setBackupSchedule;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String day(Object day);

  /// No description provided for @selectBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Select background color'**
  String get selectBackgroundColor;

  /// No description provided for @nodeColor.
  ///
  /// In en, this message translates to:
  /// **'Node Color'**
  String get nodeColor;

  /// No description provided for @selectPluginToImport.
  ///
  /// In en, this message translates to:
  /// **'Select plugin to import ({mode})'**
  String selectPluginToImport(Object mode);

  /// No description provided for @dataSize.
  ///
  /// In en, this message translates to:
  /// **'Data size: {size}'**
  String dataSize(Object size);

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get selectLocation;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select group'**
  String get selectGroup;

  /// No description provided for @videoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Video load failed: {error}'**
  String videoLoadFailed(Object error);

  /// No description provided for @loadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get loadingVideo;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Title'**
  String get pleaseEnterTitle;

  /// No description provided for @selectPluginsToImport.
  ///
  /// In en, this message translates to:
  /// **'Select Plugins To Import'**
  String get selectPluginsToImport;

  /// No description provided for @mergeMode.
  ///
  /// In en, this message translates to:
  /// **'Merge Mode'**
  String get mergeMode;

  /// No description provided for @overwriteMode.
  ///
  /// In en, this message translates to:
  /// **'Overwrite Mode'**
  String get overwriteMode;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Memento is a productivity app designed to help you organize and remember important things.'**
  String get aboutDescription;

  /// No description provided for @projectLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Project Link'**
  String get projectLinkTitle;

  /// No description provided for @projectLink.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/hunmer/memento'**
  String get projectLink;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
