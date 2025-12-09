/// WebDAV settings English translations
const Map<String, String> webdavTranslationsEn = {
  // Basic info
  'webdav_name': 'WebDAV Sync',
  'webdav_title': 'WebDAV Settings',

  // Form fields
  'webdav_serverAddress': 'Server Address',
  'webdav_serverAddressHint': 'https://example.com/webdav',
  'webdav_serverUrl': 'Server URL',
  'webdav_serverUrlHint': 'https://example.com/webdav',
  'webdav_username': 'Username',
  'webdav_usernameHint': 'Please enter username',
  'webdav_password': 'Password',
  'webdav_passwordHint': 'Please enter password',
  'webdav_rootPath': 'Root Path',
  'webdav_rootPathHint': '/webdav',

  // Advanced settings
  'webdav_advancedSettings': 'Advanced Settings',
  'webdav_connectionTimeout': 'Connection Timeout',
  'webdav_connectionTimeoutHint': 'Connection timeout in seconds',
  'webdav_useHTTPS': 'Use HTTPS',
  'webdav_verifyCertificate': 'Verify Certificate',
  'webdav_maxRetries': 'Max Retries',
  'webdav_maxRetriesHint': 'Maximum retry attempts on failure',
  'webdav_retryInterval': 'Retry Interval',
  'webdav_retryIntervalHint': 'Retry interval in seconds',

  // Sync settings
  'webdav_syncInterval': 'Sync Interval',
  'webdav_syncIntervalHint': 'Auto sync interval in minutes',
  'webdav_enableAutoSync': 'Enable Auto Sync',
  'webdav_lastSyncTime': 'Last Sync Time',

  // Data sync
  'webdav_dataSync': 'Data Sync',
  'webdav_uploadAllData': 'Upload All Data',
  'webdav_downloadAllData': 'Download All Data',
  'webdav_syncNow': 'Sync Now',

  // Action buttons
  'webdav_testConnection': 'Test Connection',
  'webdav_disconnect': 'Disconnect',
  'webdav_saveSettings': 'Save Settings',

  // Form validation errors
  'webdav_serverAddressEmptyError': 'Please enter WebDAV server address',
  'webdav_serverAddressInvalidError': 'Address must start with http:// or https://',
  'webdav_usernameEmptyError': 'Please enter username',
  'webdav_passwordEmptyError': 'Please enter password',
  'webdav_rootPathEmptyError': 'Please enter root path',
  'webdav_rootPathInvalidError': 'Path must start with /',

  // Connection status
  'webdav_connectingStatus': 'Connecting...',
  'webdav_connectionSuccessStatus': 'Connected successfully!',
  'webdav_connectionFailedStatus': 'Connection failed, please check settings',
  'webdav_connectionErrorStatus': 'Connection error: ',
  'webdav_disconnectingStatus': 'Disconnecting...',
  'webdav_disconnectedStatus': 'Disconnected',

  // Sync status
  'webdav_uploadingStatus': 'Uploading data to WebDAV...',
  'webdav_uploadSuccessStatus': 'Upload successful!',
  'webdav_uploadFailedStatus': 'Upload failed, please check connection',
  'webdav_downloadingStatus': 'Downloading data from WebDAV...',
  'webdav_downloadSuccessStatus': 'Download successful!',
  'webdav_downloadFailedStatus': 'Download failed, please check connection',
  'webdav_syncInProgress': 'Sync In Progress',
  'webdav_syncCompleted': 'Sync Completed',
  'webdav_syncFailed': 'Sync Failed',

  // Auto sync status
  'webdav_autoSyncEnabledStatus': 'Auto sync enabled, will take effect after completion',
  'webdav_autoSyncDisabledStatus': 'Auto sync disabled, will take effect after completion',

  // Success messages
  'webdav_connectionSuccess': 'Connection Success',
  'webdav_settingsSaved': 'Settings Saved',
  'webdav_settingsSavedMessage': 'Settings saved',

  // Error messages
  'webdav_connectionFailed': 'Connection Failed',
  'webdav_settingsSaveFailed': 'Settings Save Failed',
  'webdav_saveFailed': 'Save Failed',
  'webdav_invalidUrl': 'Invalid URL',
  'webdav_invalidCredentials': 'Invalid Credentials',
  'webdav_serverUnreachable': 'Server Unreachable',
  'webdav_permissionDenied': 'Permission Denied',
  'webdav_sslCertificateError': 'SSL Certificate Error',
};
