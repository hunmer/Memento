import 'package:Memento/plugins/database/l10n/database_localizations.dart';

class DatabaseLocalizationsEn extends DatabaseLocalizations {
  DatabaseLocalizationsEn() : super('en');

  @override
  String get pluginName => 'Database';

  @override
  String get pluginDescription => 'A plugin for managing databases';

  @override
  String get deleteRecordTitle => 'Delete Record';

  @override
  String get deleteRecordMessage => 'Are you sure you want to delete "%s"?';

  @override
  String get untitledRecord => 'Untitled';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';
}
