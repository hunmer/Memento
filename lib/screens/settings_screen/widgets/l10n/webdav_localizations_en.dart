import 'package:Memento/screens/settings_screen/widgets/webdav_localizations.dart';

class WebDAVLocalizationsEn implements WebDAVLocalizations {
  const WebDAVLocalizationsEn();

  @override
  String get title => 'WebDAV Sync';

  @override
  String get serverAddress => 'WebDAV Server Address';

  @override
  String get serverAddressHint => 'https://your-webdav-server.com/dav';

  @override
  String get serverAddressEmptyError => 'Please enter WebDAV server address';

  @override
  String get serverAddressInvalidError =>
      'Server address must start with http:// or https://';

  @override
  String get username => 'Username';

  @override
  String get usernameEmptyError => 'Please enter username';

  @override
  String get password => 'Password';

  @override
  String get passwordEmptyError => 'Please enter password';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get dataSync => 'Data Sync';

  @override
  String get uploadAllData => 'Upload All Data';

  @override
  String get downloadAllData => 'Download All Data';

  @override
  String get settingsSaved => 'WebDAV settings saved';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get autoSyncDisabledStatus => 'Auto sync disabled';

  @override
  String get autoSyncEnabledStatus => 'Auto sync enabled';

  @override
  String get autoSyncLabel => 'Auto Sync';

  @override
  String get autoSyncSubtitle => 'Automatically sync data periodically';

  @override
  String get connectingStatus => 'Connecting...';

  @override
  String get connectionErrorStatus => 'Connection error';

  @override
  String get connectionFailedStatus => 'Connection failed';

  @override
  String get connectionSuccessStatus => 'Connection successful';

  @override
  String get dataPathEmptyError => 'Please enter data path';

  @override
  String get dataPathHint => '/path/to/data';

  @override
  String get dataPathInvalidError => 'Invalid data path';

  @override
  String get dataPathLabel => 'Data Path';

  @override
  String get disconnectButton => 'Disconnect';

  @override
  String get disconnectedStatus => 'Disconnected';

  @override
  String get disconnectingStatus => 'Disconnecting...';

  @override
  String get downloadButton => 'Download';

  @override
  String get downloadFailedStatus => 'Download failed';

  @override
  String get downloadSuccessStatus => 'Download successful';

  @override
  String get downloadingStatus => 'Downloading...';

  @override
  String get localeName => 'English';

  @override
  String get passwordLabel => 'Password';

  @override
  String get serverAddressLabel => 'Server Address';

  @override
  String get settingsSavedMessage => 'Settings saved';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get testConnectionButton => 'Test Connection';

  @override
  String get uploadButton => 'Upload';

  @override
  String get uploadFailedStatus => 'Upload failed';

  @override
  String get uploadSuccessStatus => 'Upload successful';

  @override
  String get uploadingStatus => 'Uploading...';

  @override
  String get usernameLabel => 'Username';
}
