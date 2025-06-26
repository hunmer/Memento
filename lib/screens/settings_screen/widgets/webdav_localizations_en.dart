import 'webdav_localizations.dart';

class WebDAVLocalizationsEn extends WebDAVLocalizations {
  WebDAVLocalizationsEn() : super('en');

  @override
  String get settingsTitle => 'WebDAV Settings';

  @override
  String get serverAddressLabel => 'WebDAV Server Address';

  @override
  String get serverAddressHint => 'https://example.com/webdav';

  @override
  String get serverAddressEmptyError => 'Please enter WebDAV server address';

  @override
  String get serverAddressInvalidError => 'Address must start with http:// or https://';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameEmptyError => 'Please enter username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordEmptyError => 'Please enter password';

  @override
  String get dataPathLabel => 'Data Directory Path';

  @override
  String get dataPathHint => '/app_data';

  @override
  String get dataPathEmptyError => 'Please enter data directory path';

  @override
  String get dataPathInvalidError => 'Path must start with /';

  @override
  String get autoSyncLabel => 'Auto Sync';

  @override
  String get autoSyncSubtitle => 'Monitor local file changes and auto sync to WebDAV (excluding config files)';

  @override
  String get testConnectionButton => 'Test Connection';

  @override
  String get disconnectButton => 'Disconnect';

  @override
  String get downloadButton => 'Download';

  @override
  String get uploadButton => 'Upload';

  @override
  String get connectingStatus => 'Connecting...';

  @override
  String get connectionSuccessStatus => 'Connected successfully!';

  @override
  String get connectionFailedStatus => 'Connection failed, please check settings';

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
  String get autoSyncEnabledStatus => 'Auto sync enabled, will take effect after completion';

  @override
  String get autoSyncDisabledStatus => 'Auto sync disabled, will take effect after completion';

  @override
  String get settingsSavedMessage => 'Settings saved';
}