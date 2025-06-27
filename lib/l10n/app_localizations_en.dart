// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'memento';

  @override
  String get pluginManager => 'Plugin Manager';

  @override
  String get backupOptions => 'Backup Options';

  @override
  String get selectBackupMethod => 'Please select backup method';

  @override
  String get exportAppData => 'Export App Data';

  @override
  String get fullBackup => 'Full Backup';

  @override
  String get webdavSync => 'WebDAV Sync';

  @override
  String get selectDate => 'select Date';

  @override
  String get showAll => 'show All';

  @override
  String get ok => 'OK';

  @override
  String get select => 'Select';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get settings => 'Settings';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get interval => 'Interval';

  @override
  String get minutes => 'Minutes';

  @override
  String get tags => 'Tags';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmDelete => 'Confirm Delete?';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get date => 'Date';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Retry';

  @override
  String get rename => 'Rename';

  @override
  String get copy => 'Copy';

  @override
  String get done => 'Done';

  @override
  String get create => 'Create';

  @override
  String get adjustCardSize => 'Adjust Card Size';

  @override
  String get width => 'Width';

  @override
  String get height => 'Height';

  @override
  String get home => 'Home';

  @override
  String get noPluginsAvailable => 'No plugins available';

  @override
  String get backupInProgress => 'Backup in progress';

  @override
  String completed(Object percentage) {
    return 'Completed: $percentage%';
  }

  @override
  String get exportCancelled => 'Export cancelled';

  @override
  String get exportSuccess => 'Data exported successfully';

  @override
  String exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get warning => 'Warning';

  @override
  String get importWarning =>
      'Import will completely overwrite current app data.\nWe recommend backing up existing data before importing.\n\nContinue?';

  @override
  String get stillContinue => 'Continue';

  @override
  String get importCancelled => 'Import cancelled';

  @override
  String get selectBackupFile => 'Please select backup file';

  @override
  String get noFileSelected => 'No file selected';

  @override
  String get importInProgress => 'Import in progress';

  @override
  String get processingBackupFile => 'Processing backup file...';

  @override
  String get importSuccess => 'Data imported successfully, please restart app';

  @override
  String get restartRequired => 'Restart required';

  @override
  String get exportingData => 'exporting Data';

  @override
  String get importingData => 'importing Data';

  @override
  String get pleaseWait => 'please Wait';

  @override
  String get restartMessage =>
      'Data import completed, app restart is required to take effect.';

  @override
  String fileSelectionFailed(Object error) {
    return 'File selection failed: $error';
  }

  @override
  String get importFailed => 'Import failed';

  @override
  String get importTimeout =>
      'Import timeout: file may be too large or inaccessible';

  @override
  String get filesystemError =>
      'Filesystem error: unable to read or write file';

  @override
  String get invalidBackupFile => 'Invalid backup file: file may be corrupted';

  @override
  String dataExportedTo(Object path) {
    return 'Data exported to: $path';
  }

  @override
  String exportFailedWithError(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get noPluginDataFound => 'No plugin data found for import';

  @override
  String importFailedWithError(Object error) {
    return 'Import failed: $error';
  }

  @override
  String permissionRequired(Object permission) {
    return '$permission permission required';
  }

  @override
  String permissionRequiredForApp(Object permission) {
    return 'App requires $permission permission to work properly. Grant permission?';
  }

  @override
  String get notNow => 'Not now';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String permissionRequiredInSettings(Object permission) {
    return '$permission permission is required to continue. Please grant permission in system settings.';
  }

  @override
  String get storagePermissionRequired =>
      'Storage permission is required to continue. Please grant permission in system settings.';

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String get moveSuccess => 'Move successful';

  @override
  String moveFailed(Object error) {
    return 'Move failed: $error';
  }

  @override
  String renameFailed(Object error) {
    return 'Rename failed: $error';
  }

  @override
  String exportSuccessTo(Object path) {
    return 'Export successful to: $path';
  }

  @override
  String get selectFolderToImport => 'Select folder to import';

  @override
  String get selectPluginToExport => 'Select plugin to export';

  @override
  String get selectImage => 'Select image';

  @override
  String get selectFromGallery => 'Select from gallery';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get testForegroundTask => 'Test Foreground Task';

  @override
  String failedToLoadPlugins(Object error) {
    return 'Failed to load plugins: $error';
  }

  @override
  String get setBackupSchedule => 'Set backup schedule';

  @override
  String day(Object day) {
    return 'Day $day';
  }

  @override
  String get selectBackgroundColor => 'Select background color';

  @override
  String get nodeColor => 'Node Color';

  @override
  String selectPluginToImport(Object mode) {
    return 'Select plugin to import ($mode)';
  }

  @override
  String dataSize(Object size) {
    return 'Data size: $size';
  }

  @override
  String get import => 'Import';

  @override
  String get selectLocation => 'Select location';

  @override
  String get selectGroup => 'Select group';

  @override
  String videoLoadFailed(Object error) {
    return 'Video load failed: $error';
  }

  @override
  String get loadingVideo => 'Loading video...';

  @override
  String get pleaseEnterTitle => 'Please Enter Title';

  @override
  String get selectPluginsToImport => 'Select Plugins To Import';

  @override
  String get mergeMode => 'Merge Mode';

  @override
  String get overwriteMode => 'Overwrite Mode';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutDescription =>
      'Memento is a productivity app designed to help you organize and remember important things.';

  @override
  String get projectLinkTitle => 'Project Link';

  @override
  String get projectLink => 'https://github.com/hunmer/memento';
}
