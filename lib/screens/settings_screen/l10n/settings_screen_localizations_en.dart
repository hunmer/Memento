import 'package:Memento/screens/settings_screen/l10n/settings_screen_localizations.dart';

class SettingsScreenLocalizationsEn extends SettingsScreenLocalizations {
  SettingsScreenLocalizationsEn() : super('en');

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageTitle => 'Language (English)';

  @override
  String get languageSubtitle => 'Tap to switch to Chinese';

  @override
  String get darkModeTitle => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Toggle app theme';

  @override
  String get exportDataTitle => 'Export App Data';

  @override
  String get exportDataSubtitle => 'Export plugin data to file';

  @override
  String get dataManagementTitle => 'Data File Management';

  @override
  String get dataManagementSubtitle => 'Manage files in app data directory';

  @override
  String get importDataTitle => 'Import App Data';

  @override
  String get importDataSubtitle => 'Import plugin data from file';

  @override
  String get fullBackupTitle => 'Full Backup';

  @override
  String get fullBackupSubtitle => 'Backup entire app data directory';

  @override
  String get fullRestoreTitle => 'Full Restore';

  @override
  String get fullRestoreSubtitle => 'Restore entire app data from backup (overwrites existing data)';

  @override
  String get webDAVTitle => 'WebDAV Sync';

  @override
  String get webDAVConnected => 'Connected';

  @override
  String get webDAVDisconnected => 'Disconnected';

  @override
  String get floatingBallTitle => 'Floating Ball Settings';

  @override
  String get floatingBallEnabled => 'Enabled';

  @override
  String get floatingBallDisabled => 'Disabled';

  @override
  String get autoBackupTitle => 'Auto Backup Settings';

  @override
  String get autoBackupSubtitle => 'Set auto backup schedule';

  @override
  String get autoOpenLastPluginTitle => 'Auto Open Last Used Plugin';

  @override
  String get autoOpenLastPluginSubtitle => 'Automatically open last used plugin on startup';

  @override
  String get autoCheckUpdateTitle => 'Auto Check Updates';

  @override
  String get autoCheckUpdateSubtitle => 'Periodically check for new app versions';

  @override
  String get checkUpdateTitle => 'Check Updates';

  @override
  String get checkUpdateSubtitle => 'Check for new app versions now';

  @override
  String get logSettingsTitle => 'Log Settings';

  @override
  String get logSettingsSubtitle => 'Configure logging options';

  @override
  String get testForegroundTaskTitle => 'Test Foreground Service';
}