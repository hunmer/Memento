/// Settings screen English translations
const Map<String, String> settingsScreenTranslationsEn = {
  // Page title
  'settings_screen_settingsTitle': 'Settings',

  // Language settings
  'settings_screen_languageTitle': 'Language (English)',
  'settings_screen_languageSubtitle': 'Tap to switch to Chinese',

  // Theme settings
  'settings_screen_darkModeTitle': 'Dark Mode',
  'settings_screen_darkModeSubtitle': 'Toggle app theme',

  // Data management
  'settings_screen_exportDataTitle': 'Export App Data',
  'settings_screen_exportDataSubtitle': 'Export plugin data to file',
  'settings_screen_dataManagementTitle': 'Data File Management',
  'settings_screen_dataManagementSubtitle': 'Manage files in app data directory',
  'settings_screen_importDataTitle': 'Import App Data',
  'settings_screen_importDataSubtitle': 'Import plugin data from file',
  'settings_screen_fullBackupTitle': 'Full Backup',
  'settings_screen_fullBackupSubtitle': 'Backup entire app data directory',
  'settings_screen_fullRestoreTitle': 'Full Restore',
  'settings_screen_fullRestoreSubtitle': 'Restore entire app data from backup (overwrites existing data)',

  // WebDAV sync
  'settings_screen_webDAVTitle': 'WebDAV Sync',
  'settings_screen_webDAVConnected': 'Connected',
  'settings_screen_webDAVDisconnected': 'Disconnected',

  // Server sync
  'settings_screen_serverSyncTitle': 'Server Sync',
  'settings_screen_serverSyncConnected': 'Logged in',
  'settings_screen_serverSyncDisconnected': 'Not logged in',

  // Floating ball settings
  'settings_screen_floatingBallTitle': 'Floating Ball Settings',
  'settings_screen_floatingBallEnabled': 'Enabled',
  'settings_screen_floatingBallDisabled': 'Disabled',

  // Auto backup settings
  'settings_screen_autoBackupTitle': 'Auto Backup Settings',
  'settings_screen_autoBackupSubtitle': 'Set auto backup schedule',

  // Plugin management
  'settings_screen_pluginManagementTitle': 'Plugin Management',
  'settings_screen_pluginManagementSubtitle': 'Choose which plugins load on startup',
  'settings_screen_pluginManagementTip': 'Disabled plugins will skip initialization on next launch. Re-enable them to restore.',

  // Auto open last plugin
  'settings_screen_autoOpenLastPluginTitle': 'Auto Open Last Used Plugin',
  'settings_screen_autoOpenLastPluginSubtitle': 'Automatically open last used plugin on startup',

  // Update check
  'settings_screen_autoCheckUpdateTitle': 'Auto Check Updates',
  'settings_screen_autoCheckUpdateSubtitle': 'Periodically check for new app versions',
  'settings_screen_checkUpdateTitle': 'Check Updates',
  'settings_screen_checkUpdateSubtitle': 'Check for new app versions now',

  // Update prompts
  'settings_screen_updateAvailableTitle': 'New version available',
  'settings_screen_updateAvailableContent': 'Current version: @currentVersion\nLatest version: @latestVersion\nRelease notes:',
  'settings_screen_updateLaterButton': 'Later',
  'settings_screen_updateViewButton': 'View update',
  'settings_screen_alreadyLatestVersion': 'You already have the latest version',
  'settings_screen_updateCheckFailed': 'Update check failed: @error',
  'settings_screen_checkingForUpdates': 'Checking for updates...',

  // Server sync settings
  'server_sync_title': 'Server Sync',
  'server_sync_loggedIn': 'Logged in',
  'server_sync_serverAddress': 'Server Address',
  'server_sync_serverAddressRequired': 'Please enter server address',
  'server_sync_serverAddressInvalid': 'Please enter a valid server address (starting with http:// or https://)',
  'server_sync_username': 'Username',
  'server_sync_usernameRequired': 'Please enter username',
  'server_sync_password': 'Password',
  'server_sync_passwordRequired': 'Please enter password',
  'server_sync_deviceName': 'Device Name',
  'server_sync_login': 'Login',
  'server_sync_register': 'Register',
  'server_sync_logout': 'Logout',
  'server_sync_saveSettings': 'Save Settings',
  'server_sync_testConnection': 'Test Connection',
  'server_sync_connectionSuccess': 'Connection successful',
  'server_sync_connectionFailed': 'Connection failed',
  'server_sync_loginSuccess': 'Login successful',
  'server_sync_loginFailed': 'Login failed',
  'server_sync_registerSuccess': 'Registration successful',
  'server_sync_registerFailed': 'Registration failed',
  'server_sync_logoutSuccess': 'Logged out',
  'server_sync_logoutFailed': 'Logout failed',
  'server_sync_settingsSaved': 'Settings saved',
  'server_sync_saveFailed': 'Save failed',
  'server_sync_notLoggedIn': 'Please login first',
  'server_sync_syncSettings': 'Sync Settings',
  'server_sync_autoSync': 'Auto Sync',
  'server_sync_autoSyncSubtitle': 'Automatically sync data to server periodically',
  'server_sync_syncInterval': 'Sync Interval',
  'server_sync_minutes': 'minutes',
  'server_sync_syncOnChange': 'Sync on File Change',
  'server_sync_syncOnChangeSubtitle': 'Automatically trigger sync when local files change',
  'server_sync_syncOnStart': 'Sync on Startup',
  'server_sync_syncOnStartSubtitle': 'Automatically pull latest data from server when app starts',
  'server_sync_syncDirs': 'Sync Directories',
  'server_sync_selected': 'Selected',
  'server_sync_syncNow': 'Sync Now',
  'server_sync_syncComplete': 'Sync complete: @success success, @conflict conflicts, @error errors',
  'server_sync_syncFailed': 'Sync failed',
  'server_sync_encryptionKey': 'Encryption Key',
  'server_sync_encryptionKeyHint': '⚠️ This key is used for admin panel API access. Keep it secure and do not share',
  'server_sync_copyKey': 'Copy Key',
  'server_sync_keyCopied': 'Key copied to clipboard',

  // Language selection dialog
  'settingsScreen_selectLanguage': 'Select Language',
  'settingsScreen_chinese': '中文',
  'settingsScreen_english': 'English',
};
