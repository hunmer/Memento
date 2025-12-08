import 'core_localizations.dart';

/// 核心模块中文国际化
class CoreLocalizationsZh extends CoreLocalizations {
  @override
  String get starting => '正在启动...';

  @override
  String get inputJavaScriptCode => '输入JavaScript代码';

  @override
  String get cancel => '取消';

  @override
  String get execute => '执行';

  @override
  String get save => '保存';

  @override
  String get executionResult => '执行结果';

  @override
  String executionStatus(bool success) => '执行状态: ${success ? "成功" : "失败"}';

  @override
  String get outputData => '输出数据:';

  @override
  String get errorMessage => '错误信息:';

  @override
  String get close => '关闭';

  @override
  String get inputFloatingBallJavaScriptCode => '输入悬浮球JavaScript代码';

  @override
  String get configMigration => '配置迁移';

  @override
  String get migrating => '迁移中...';

  @override
  String get startMigration => '开始迁移';

  @override
  String get notSelected => '未选择';

  @override
  String get selectColor => '选择颜色';

  @override
  String get iconSelectorNotImplemented => '图标选择器（暂未实现）';

  @override
  String get sequentialExecution => '顺序执行';

  @override
  String get parallelExecution => '并行执行';

  @override
  String get conditionalExecution => '条件执行';

  @override
  String get executeAllActions => '执行所有动作';

  @override
  String get executeAnyAction => '执行任一动作';

  @override
  String get executeFirstOnly => '只执行第一个';

  @override
  String get executeLastOnly => '只执行最后一个';

  @override
  String get addAction => '添加动作';

  @override
  String get edit => '编辑';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String get delete => '删除';

  @override
  String get clearSettings => '清除已设置';

  @override
  String get confirm => '确认';

  @override
  String get confirmDelete => '确认删除';

  @override
  String confirmDeleteButton(String title) => '确定要删除按钮"$title"吗？';

  @override
  String get floatingButtonManager => '悬浮按钮管理';

  @override
  String get addFirstButton => '添加第一个按钮';

  @override
  String get clearIconImage => '清空图标/图片';

  @override
  String confirmClearIconImage() => '确定要清空当前设置的图标和图片吗？';

  @override
  String get clear => '清空';

  @override
  String get selectIcon => '选择图标';

  @override
  String get routeError => '路由错误';

  @override
  String routeNotFound(String routeName) => '未找到路由: $routeName';

  @override
  String get createActionGroup => '创建动作组';
}
