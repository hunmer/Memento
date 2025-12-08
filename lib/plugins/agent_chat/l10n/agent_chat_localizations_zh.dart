import 'dart:ui';

import 'agent_chat_localizations.dart';

class AgentChatLocalizationsZh extends AgentChatLocalizations {
  const AgentChatLocalizationsZh() : super(const Locale('zh'));

  // 对话列表页面
  @override
  String get conversationListTitle => 'AI 对话';
  @override
  String get groupManagement => '分组管理';
  @override
  String get editGroup => '编辑分组';
  @override
  String get addGroup => '添加分组';
  @override
  String get addChannel => '添加频道';
  @override
  String get create => '创建';
  @override
  String get editConversation => '编辑会话';
  @override
  String get confirmDelete => '确认删除';
  @override
  String get delete => '删除';
  @override
  String get selectCreateType => '选择要创建的类型';
  @override
  String get channel => '频道';
  @override
  String get channelDescription => '创建新的对话频道';
  @override
  String get group => '分组';
  @override
  String get groupDescription => '创建新的分组分类';
  @override
  String get clear => '清除';

  // 聊天页面
  @override
  String get selectAgent => '选择Agent';
  @override
  String get createNewChat => '创建新聊天';
  @override
  String get tokenStatistics => 'Token统计';
  @override
  String get close => '关闭';
  @override
  String get conversationSettings => '会话设置';
  @override
  String get useGlobalSettings => '使用全局设置';
  @override
  String get custom => '自定义';
  @override
  String get save => '保存';
  @override
  String get cancel => '取消';
  @override
  String get confirmClear => '确认清空';
  @override
  String get confirmClearTools => '确定要清空所有选中的工具吗？';
  @override
  String get confirmDeleteMessage => '确定要删除这条消息吗？';
  @override
  String get editMessage => '编辑消息';
  @override
  String get toolExecutionResult => '工具执行结果';
  @override
  String get image => '图片';
  @override
  String get document => '文档';

  // 工具模板页面
  @override
  String get toolTemplate => '工具模板';
  @override
  String get selectTagFilter => '选择标签过滤';
  @override
  String get use => '使用';
  @override
  String get deleteConfirm => '删除确认';
  @override
  String get reset => '重置';
  @override
  String get confirm => '确定';

  // 工具管理页面
  @override
  String get toolManagement => '工具管理';
  @override
  String get selectPlugin => '选择插件';
  @override
  String get confirmImport => '确认导入';
  @override
  String get importConfigOverride => '导入配置将覆盖现有配置，是否继续？';
  @override
  String get confirmRestoreDefault => '确认恢复默认';
  @override
  String get restoreDefaultDescription => '此操作将删除所有自定义配置，恢复到默认配置。是否继续？';
  @override
  String get restoreDefault => '恢复默认';
  @override
  String get all => '全部';
  @override
  String get disabledTools => '已禁用的工具';
  @override
  String get enableAll => '全部启用';
  @override
  String get confirmEnableAll => '确认全部启用';

  // 设置页面
  @override
  String get agentChatSettings => 'Agent Chat 设置';
  @override
  String get prioritizeToolTemplate => '优先使用工具模版';
  @override
  String get prioritizeToolTemplateDescription => '启用后，AI将优先使用预定义的工具模板执行任务';
  @override
  String get enableBackgroundService => '启用后台服务';
  @override
  String get enableBackgroundServiceDescription =>
      '切换到其他应用后继续接收AI回复。会显示前台通知以保持服务运行。';
  @override
  String get showTokenConsumption => '显示Token消耗';
  @override
  String get showTokenConsumptionDescription => '在通知中实时显示输入/输出token数量和总消耗。';
  @override
  String get testConfiguration => '测试配置';
  @override
  String get saveSettings => '保存设置';

  // 配置对话框
  @override
  String get configuration => '配置';
  @override
  String get advancedConfiguration => '高级配置';
  @override
  String get confirmSave => '确认保存';
  @override
  String get confirmSaveDescription => '确定要保存配置吗？';
  @override
  String get copyResult => '复制结果';
  @override
  String get executeAgain => '重新执行此步骤';

  // 新增的硬编码文本
  @override
  String initializationFailed(String error) => '初始化失败: $error';
  @override
  String get goBack => '返回';

  // 消息操作
  @override
  String get copy => '复制';
  @override
  String get edit => '编辑';
  @override
  String get regenerate => '重新生成';
  @override
  String get saveTool => '保存工具';
  @override
  String get reExecuteTool => '重新执行工具';
  @override
  String get viewDetails => '查看详情';
  @override
  String get deleteTask => '删除任务';
  @override
  String confirmDeleteTask(String taskName) => '确定要删除这个任务吗？';
  @override
  String get send => '发送';

  // 工具相关
  @override
  String get addTool => '添加工具';
  @override
  String get importConfig => '导入配置';
  @override
  String get exportConfig => '导出配置';
  @override
  String get noToolConfig => '暂无工具配置';
  @override
  String get allToolsEnabled => '所有工具都已启用！';
  @override
  String confirmEnableAllTools(int count) => '确定要启用所有 $count 个已禁用的工具吗？';
  @override
  String get enableTool => '启用工具';
  @override
  String get disableToolWarning => '禁用后该工具将不会提供给AI使用';
  @override
  String get addParameter => '添加参数';
  @override
  String get noParametersClickToAdd => '暂无参数，点击上方按钮添加';
  @override
  String get optionalParameter => '可选参数';
  @override
  String get addExample => '添加示例';
  @override
  String get noExamplesClickToAdd => '暂无示例，点击上方按钮添加';
  @override
  String get test => '测试';
  @override
  String get executingJSCode => '正在执行 JS 代码...';
  @override
  String confirmDeleteTool(String toolId) => '确定要删除工具 "$toolId" 吗？';
  @override
  String get deleteConfirmation => '删除确认';
  @override
  String confirmDeleteTemplate(String templateName) => '确定要删除工具模板"$templateName"吗？';
  @override
  String get resetConfirmation => '重置确认';
  @override
  String get resettingDefaultTemplates => '正在重置默认模板...';

  // 创建对话框
  @override
  String get selectTypeToCreate => '选择要创建的类型';
  @override
  String get createNewConversationChannel => '创建新的对话频道';
  @override
  String get createNewGroupCategory => '创建新的分组分类';

  // 分组相关
  @override
  String confirmDeleteGroup(String groupName) => '确定要删除分组 "$groupName" 吗？\n\n此操作将同时清除该分组的筛选状态。';
  @override
  String get aiChat => 'AI 对话';

  // 插件信息
  @override
  String pluginInfo(String pluginId, int enabledCount, int totalCount) => '$pluginId ($enabledCount/$totalCount)';

  // 确认删除会话
  @override
  String confirmDeleteConversation(String title) => '确定要删除会话 "$title" 吗？\n\n此操作将同时删除所有消息记录，且不可恢复。';

  // 空状态
  @override
  String get loadingToolTemplates => '正在加载工具模板...';
  @override
  String get noToolTemplates => '暂无工具模板';
  @override
  String get noChannels => '暂无频道';
  @override
  String get noGroups => '暂无分组';
  @override
  String get noMessages => '暂无消息';
  @override
  String get emptyConversationHistory => '空白的对话历史';
}
