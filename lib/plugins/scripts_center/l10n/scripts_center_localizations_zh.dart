import 'scripts_center_localizations.dart';

/// 中文本地化实现
class ScriptsCenterLocalizationsZh extends ScriptsCenterLocalizations {
  ScriptsCenterLocalizationsZh() : super('zh');

  @override
  String get name => '脚本中心';

  @override
  String get scriptCenter => '脚本中心';

  @override
  String get format => '格式化';

  @override
  String get addTrigger => '添加触发器';

  @override
  String get addTriggerCondition => '添加触发条件';

  @override
  String get add => '添加';

  @override
  String categoryLabel(String category) => '类别: $category';

  @override
  String descriptionLabel(String description) => '描述: $description';

  @override
  String delayLabel(int delay) => '延迟: ${delay}ms';

  @override
  String get moduleType => 'Module（可接受参数）';

  @override
  String get standaloneType => 'Standalone（独立运行）';

  @override
  String get addInputParameter => '添加输入参数';

  @override
  String get enableScript => '启用脚本';

  @override
  String get requiredParameter => '必填参数';

  @override
  String get userMustFillThisParameter => '用户必须填写此参数';

  @override
  String get thisParameterIsOptional => '此参数可选';

  @override
  String get cancel => '取消';

  @override
  String get run => '运行';

  @override
  String get all => '全部';
}