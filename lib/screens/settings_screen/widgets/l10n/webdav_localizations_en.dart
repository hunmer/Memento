import 'package:Memento/screens/settings_screen/widgets/l10n/webdav_localizations.dart';
import 'package:flutter/widgets.dart';

class WebDAVLocalizationsEn extends WebDAVLocalizations {
  WebDAVLocalizationsEn() : super('en');

  @override
  String get pluginName => 'WebDAV Settings';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'Enter WebDAV server URL';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Enter your username';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get connectionSuccess => 'Connection successful';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get settingsSaveFailed => 'Failed to save settings';

  @override
  String get rootPath => 'Root Path';

  @override
  String get rootPathHint => 'Enter root path on server';

  @override
  String get syncInterval => 'Sync Interval';

  @override
  String get syncIntervalHint => 'Set sync interval in minutes';

  @override
  String get enableAutoSync => 'Enable Auto Sync';

  @override
  String get lastSyncTime => 'Last Sync Time';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncInProgress => 'Sync in progress...';

  @override
  String get syncCompleted => 'Sync completed';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get serverUnreachable => 'Server unreachable';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get sslCertificateError => 'SSL certificate error';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get connectionTimeout => 'Connection Timeout';

  @override
  String get connectionTimeoutHint => 'Set timeout in seconds';

  @override
  String get useHTTPS => 'Use HTTPS';

  @override
  String get verifyCertificate => 'Verify Certificate';

  @override
  String get maxRetries => 'Max Retries';

  @override
  String get maxRetriesHint => 'Set maximum retry attempts';

  @override
  String get retryInterval => 'Retry Interval';

  @override
  String get retryIntervalHint => 'Set retry interval in seconds';

  @override
  String get dataSync => 'Data Sync';

  @override
  String get downloadAllData => 'Download All Data';

  @override
  String get passwordEmptyError => 'Password cannot be empty';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get serverAddress => 'Server Address';

  @override
  String get serverAddressEmptyError => 'Server address cannot be empty';

  @override
  String get serverAddressHint => 'Enter server address';

  @override
  String? get serverAddressInvalidError => 'Invalid server address';

  @override
  String get title => 'WebDAV Settings';

  @override
  String get uploadAllData => 'Upload All Data';

  @override
  String get usernameEmptyError => 'Username cannot be empty';
}
