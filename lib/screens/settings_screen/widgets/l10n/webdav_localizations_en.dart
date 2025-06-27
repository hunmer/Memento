import 'webdav_localizations.dart';

class WebDAVLocalizationsEn extends WebDAVLocalizations {
  WebDAVLocalizationsEn() : super('en');
  @override
  String get serverAddressHint => 'https://example.com/webdav';

  @override
  String get serverAddressEmptyError => 'Please enter WebDAV server address';

  @override
  String get serverAddressInvalidError =>
      'Address must start with http:// or https://';

  @override
  String get usernameEmptyError => 'Please enter username';

  @override
  String get passwordEmptyError => 'Please enter password';

  @override
  String get connectingStatus => 'Connecting...';

  @override
  String get connectionSuccessStatus => 'Connected successfully!';

  @override
  String get connectionFailedStatus =>
      'Connection failed, please check settings';

  @override
  String get connectionErrorStatus => 'Connection error: ';

  @override
  String get disconnectingStatus => 'Disconnecting...';

  @override
  String get disconnectedStatus => 'Disconnected';

  @override
  String get uploadingStatus => 'Uploading data to WebDAV...';

  @override
  String get uploadSuccessStatus => 'Upload successful!';

  @override
  String get uploadFailedStatus => 'Upload failed, please check connection';

  @override
  String get downloadingStatus => 'Downloading data from WebDAV...';

  @override
  String get downloadSuccessStatus => 'Download successful!';

  @override
  String get downloadFailedStatus => 'Download failed, please check connection';

  @override
  String get autoSyncEnabledStatus =>
      'Auto sync enabled, will take effect after completion';

  @override
  String get autoSyncDisabledStatus =>
      'Auto sync disabled, will take effect after completion';

  @override
  String get settingsSavedMessage => 'Settings saved';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get connectionFailed => 'Connection Failed';

  @override
  String get connectionSuccess => 'Connection Success';

  @override
  String get connectionTimeout => 'Connection Timeout';

  @override
  String get connectionTimeoutHint => 'Connection timeout in seconds';

  @override
  String get dataSync => 'Data Sync';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get downloadAllData => 'Download All Data';

  @override
  String get enableAutoSync => 'Enable Auto Sync';

  @override
  String get invalidCredentials => 'Invalid Credentials';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get lastSyncTime => 'Last Sync Time';

  @override
  String get maxRetries => 'Max Retries';

  @override
  String get maxRetriesHint => 'Maximum retry attempts on failure';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Please enter password';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get name => 'WebDAV Sync';

  @override
  String get retryInterval => 'Retry Interval';

  @override
  String get retryIntervalHint => 'Retry interval in seconds';

  @override
  String get rootPath => 'Root Path';

  @override
  String get rootPathEmptyError => 'Please enter root path';

  @override
  String get rootPathHint => '/webdav';

  @override
  String? get rootPathInvalidError => 'Path must start with /';

  @override
  String get saveFailed => 'Save Failed';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get serverAddress => 'Server Address';

  @override
  String get serverUnreachable => 'Server Unreachable';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'https://example.com/webdav';

  @override
  String get settingsSaveFailed => 'Settings Save Failed';

  @override
  String get settingsSaved => 'Settings Saved';

  @override
  String get sslCertificateError => 'SSL Certificate Error';

  @override
  String get syncCompleted => 'Sync Completed';

  @override
  String get syncFailed => 'Sync Failed';

  @override
  String get syncInProgress => 'Sync In Progress';

  @override
  String get syncInterval => 'Sync Interval';

  @override
  String get syncIntervalHint => 'Auto sync interval in minutes';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get title => 'WebDAV Settings';

  @override
  String get uploadAllData => 'Upload All Data';

  @override
  String get useHTTPS => 'Use HTTPS';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Please enter username';

  @override
  String get verifyCertificate => 'Verify Certificate';
}
