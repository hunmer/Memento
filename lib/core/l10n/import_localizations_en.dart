import 'package:Memento/core/l10n/import_localizations.dart';

class ImportLocalizationsEn extends ImportLocalizations {
  ImportLocalizationsEn() : super('en');

  @override
  String get filePathError => 'Failed to get file path';

  @override
  String get noPluginsFound => 'No plugin data found for import';

  @override
  String get importSuccess => 'Import successful';

  @override
  String get importSuccessContent =>
      'Data has been successfully imported. The app needs to be restarted to apply changes.';

  @override
  String get restartLater => 'Restart later';

  @override
  String get restartNow => 'Restart now';

  @override
  String get importFailed => 'Import failed';
}
