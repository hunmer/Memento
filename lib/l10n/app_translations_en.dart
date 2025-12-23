/// English translations for app-level strings
///
/// All keys are prefixed with 'app_' to avoid conflicts with plugin translations.
/// Parameterized translations use @paramName format for GetX.
const Map<String, String> appTranslationsEn = {
  // App basics
  'app_appTitle': 'memento',
  'app_pluginManager': 'Plugin Manager',
  'app_home': 'Home',
  'app_settings': 'Settings',
  'app_version': 'Version',

  // Common actions
  'app_ok': 'OK',
  'app_select': 'Select',
  'app_no': 'No',
  'app_yes': 'Yes',
  'app_cancel': 'Cancel',
  'app_save': 'Save',
  'app_close': 'Close',
  'app_delete': 'Delete',
  'app_reset': 'Reset',
  'app_apply': 'Apply',
  'app_edit': 'Edit',
  'app_retry': 'Retry',
  'app_rename': 'Rename',
  'app_copy': 'Copy',
  'app_done': 'Done',
  'app_create': 'Create',
  'app_confirm': 'Confirm',
  'app_import': 'Import',

  // Delete confirmation
  'app_confirmDelete': 'Confirm Delete?',

  // Date and time
  'app_selectDate': 'select Date',
  'app_startTime': 'Start Time',
  'app_endTime': 'End Time',
  'app_interval': 'Interval',
  'app_minutes': 'Minutes',
  'app_week': 'Week',
  'app_month': 'Month',
  'app_date': 'Date',
  'app_day': 'Day @day',

  // Display options
  'app_showAll': 'show All',
  'app_adjustCardSize': 'Adjust Card Size',
  'app_width': 'Width',
  'app_height': 'Height',

  // Tags and categories
  'app_tags': 'Tags',
  'app_selectGroup': 'Select group',
  'app_selectLocation': 'Select location',

  // Backup and export
  'app_backupOptions': 'Backup Options',
  'app_selectBackupMethod': 'Please select backup method',
  'app_exportAppData': 'Export App Data',
  'app_fullBackup': 'Full Backup',
  'app_webdavSync': 'WebDAV Sync',
  'app_setBackupSchedule': 'Set backup schedule',

  // Backup progress
  'app_backupInProgress': 'Backup in progress',
  'app_completed': 'Completed: @percentage%',
  'app_exportingData': 'exporting Data',
  'app_importingData': 'importing Data',
  'app_pleaseWait': 'please Wait',

  // Export messages
  'app_exportCancelled': 'Export cancelled',
  'app_exportSuccess': 'Data exported successfully',
  'app_exportFailed': 'Export failed: @error',
  'app_dataExportedTo': 'Data exported to: @path',
  'app_exportFailedWithError': 'Export failed: @error',
  'app_exportSuccessTo': 'Export successful to: @path',

  // Import messages
  'app_warning': 'Warning',
  'app_importWarning':
      'Import will completely overwrite current app data.\nWe recommend backing up existing data before importing.\n\nContinue?',
  'app_stillContinue': 'Continue',
  'app_importCancelled': 'Import cancelled',
  'app_selectBackupFile': 'Please select backup file',
  'app_noFileSelected': 'No file selected',
  'app_importInProgress': 'Import in progress',
  'app_processingBackupFile': 'Processing backup file...',
  'app_importSuccess': 'Data imported successfully, please restart app',
  'app_restartRequired': 'Restart required',
  'app_restartMessage':
      'Data import completed, app restart is required to take effect.',
  'app_fileSelectionFailed': 'File selection failed: @error',
  'app_importFailed': 'Import failed',
  'app_importTimeout': 'Import timeout: file may be too large or inaccessible',
  'app_filesystemError': 'Filesystem error: unable to read or write file',
  'app_invalidBackupFile': 'Invalid backup file: file may be corrupted',
  'app_noPluginDataFound': 'No plugin data found for import',
  'app_importFailedWithError': 'Import failed: @error',

  // Plugin management
  'app_noPluginsAvailable': 'No plugins available',
  'app_failedToLoadPlugins': 'Failed to load plugins: @error',
  'app_selectPluginToExport': 'Select plugin to export',
  'app_selectPluginToImport': 'Select plugin to import (@mode)',
  'app_selectPluginsToImport': 'Select Plugins To Import',
  'app_selectFolderToImport': 'Select folder to import',
  'app_dataSize': 'Data size: @size',
  'app_mergeMode': 'Merge Mode',
  'app_overwriteMode': 'Overwrite Mode',

  // Permissions
  'app_permissionRequired': '@permission permission required',
  'app_permissionRequiredForApp':
      'App requires @permission permission to work properly. Grant permission?',
  'app_notNow': 'Not now',
  'app_grantPermission': 'Grant permission',
  'app_permissionRequiredInSettings':
      '@permission permission is required to continue. Please grant permission in system settings.',
  'app_storagePermissionRequired':
      'Storage permission is required to continue. Please grant permission in system settings.',
  'app_permissionsTitle': 'Permission access',
  'app_permissionsDescription':
      'Grant these permissions to ensure backups, imports, and reminders continue to work properly.',
  'app_permissionsGrantAll': 'Grant all permissions',
  'app_permissionsGranted': 'Granted',
  'app_permissionsRequest': 'Allow',
  'app_permissionsOpenSettings': 'Open settings',
  'app_permissionsManageDescription':
      'Review and manage multimedia and notification permissions.',
  'app_permission_photosTitle': 'Photos',
  'app_permission_photosDescription':
      'Required to pick and back up images inside diary, check-in, and other plugins.',
  'app_permission_videosTitle': 'Videos',
  'app_permission_videosDescription':
      'Required to attach and export recorded videos.',
  'app_permission_audioTitle': 'Audio',
  'app_permission_audioDescription':
      'Required to capture voice notes and attach audio files.',
  'app_permission_notificationsTitle': 'Notifications',
  'app_permission_notificationsDescription':
      'Required to deliver reminders and scheduled alerts.',
  'app_permission_storageTitle': 'Storage',
  'app_permission_storageDescription':
      'Required to read and write backup files on your device.',
  'app_permission_calendarTitle': 'Calendar',
  'app_permission_calendarDescription':
      'Required to sync system calendar and manage calendar events.',

  // File operations
  'app_downloadCancelled': 'Download cancelled',
  'app_moveSuccess': 'Move successful',
  'app_moveFailed': 'Move failed: @error',
  'app_renameFailed': 'Rename failed: @error',

  // Media selection
  'app_selectImage': 'Select image',
  'app_selectFromGallery': 'Select from gallery',
  'app_takePhoto': 'Take photo',
  'app_loadingVideo': 'Loading video...',
  'app_videoLoadFailed': 'Video load failed: @error',

  // Form validation
  'app_pleaseEnterTitle': 'Please Enter Title',
  'app_titleRequired': 'Title is required',

  // Colors
  'app_selectBackgroundColor': 'Select background color',
  'app_nodeColor': 'Node Color',

  // Testing
  'app_testForegroundTask': 'Test Foreground Task',

  // About
  'app_aboutTitle': 'About',
  'app_aboutDescription':
      'Memento is a productivity app designed to help you organize and remember important things.',
  'app_projectLinkTitle': 'Project Link',
  'app_projectLink': 'https://github.com/hunmer/memento',
  'app_feedbackTitle': 'Feedback & Issues',
  'app_feedbackLink': 'https://github.com/hunmer/Memento/issues',
  'app_documentationTitle': 'Documentation',
  'app_documentationLink': 'https://github.com/hunmer/Memento#readme',

  // Home Widget Categories
  'home_categoryRecord': 'Record',
  'home_categoryTools': 'Tools',
  'home_categoryCommunication': 'Communication',
  'home_categoryFinance': 'Finance',
  'home_categoryLife': 'Life',
  'home_loadFailed': 'Load Failed',
};
