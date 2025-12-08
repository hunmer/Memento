import 'scripts_center_localizations.dart';

/// 英文本地化实现
class ScriptsCenterLocalizationsEn extends ScriptsCenterLocalizations {
  ScriptsCenterLocalizationsEn() : super('en');

  @override
  String get name => 'Script Center';

  @override
  String get scriptCenter => 'Script Center';

  @override
  String get format => 'Format';

  @override
  String get addTrigger => 'Add Trigger';

  @override
  String get addTriggerCondition => 'Add Trigger Condition';

  @override
  String get add => 'Add';

  @override
  String categoryLabel(String category) => 'Category: $category';

  @override
  String descriptionLabel(String description) => 'Description: $description';

  @override
  String delayLabel(int delay) => 'Delay: ${delay}ms';

  @override
  String get moduleType => 'Module (Accepts Parameters)';

  @override
  String get standaloneType => 'Standalone (Runs Independently)';

  @override
  String get addInputParameter => 'Add Input Parameter';

  @override
  String get enableScript => 'Enable Script';

  @override
  String get requiredParameter => 'Required Parameter';

  @override
  String get userMustFillThisParameter => 'User must fill this parameter';

  @override
  String get thisParameterIsOptional => 'This parameter is optional';

  @override
  String get cancel => 'Cancel';

  @override
  String get run => 'Run';

  @override
  String get all => 'All';
}