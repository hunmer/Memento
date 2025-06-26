import 'package:Memento/plugins/database/l10n/database_localizations.dart';

class DatabaseLocalizationsZh extends DatabaseLocalizations {
  DatabaseLocalizationsZh() : super('zh');

  @override
  String get pluginName => '数据库';

  @override
  String get pluginDescription => '用于管理数据库的插件';

  @override
  String get deleteRecordTitle => '删除记录';

  @override
  String get deleteRecordMessage => '确定要删除"%s"吗？';

  @override
  String get untitledRecord => '未命名';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';
}