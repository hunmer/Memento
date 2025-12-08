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
  String get noActionsFound => '没有找到动作';

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

  @override
  String get pleaseAddAtLeastOneAction => '请至少添加一个动作';

  @override
  String get singleAction => '单动作';

  @override
  String get actionGroup => '动作组';

  @override
  String get customAction => '自定义';

  @override
  String get noActionGroups => '没有动作组';

  @override
  String get noCustomActions => '没有自定义动作';

  @override
  String get selectAction => '选择动作';

  @override
  String get searchActions => '搜索动作...';

  @override
  String get actionConfig => '动作配置';

  @override
  String get noDescription => '无描述';

  @override
  String actionsCount(int count) => '$count 个动作';

  @override
  String get editActionGroup => '编辑动作组';

  @override
  String get createActionGroupTitle => '创建动作组';

  @override
  String get basicInfo => '基本信息';

  @override
  String get groupTitle => '组标题';

  @override
  String get enterActionGroupTitle => '输入动作组标题';

  @override
  String get pleaseEnterGroupTitle => '请输入组标题';

  @override
  String get groupDescription => '组描述';

  @override
  String get enterActionGroupDescription => '输入动作组描述（可选）';

  @override
  String get executionConfig => '执行配置';

  @override
  String get operator => '操作符';

  @override
  String get selectExecutionMethod => '选择执行方式';

  @override
  String get executionMode => '执行模式';

  @override
  String get selectExecutionMode => '选择执行模式';

  @override
  String get priority => '优先级';

  @override
  String get priorityDescription => '数字越大优先级越高';

  @override
  String get actionList => '动作列表';

  @override
  String get noActionsAdded => '暂无动作，点击上方按钮添加';
}
