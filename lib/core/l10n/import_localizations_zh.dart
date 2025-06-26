import 'package:Memento/core/l10n/import_localizations.dart';

class ImportLocalizationsZh extends ImportLocalizations {
  ImportLocalizationsZh() : super('zh');

  @override
  String get filePathError => '无法获取文件路径';

  @override
  String get noPluginsFound => '没有找到可导入的插件数据';

  @override
  String get importSuccess => '导入成功';

  @override
  String get importSuccessContent => '数据已成功导入。需要重启应用以应用更改。';

  @override
  String get restartLater => '稍后重启';

  @override
  String get restartNow => '立即重启';

  @override
  String get importFailed => '导入失败';
}
