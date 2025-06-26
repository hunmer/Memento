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
}
