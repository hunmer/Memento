import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AgentChatLocalizations {
  const AgentChatLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AgentChatLocalizations> delegate =
      _AgentChatLocalizationsDelegate();

  static AgentChatLocalizations of(BuildContext context) {
    return Localizations.of<AgentChatLocalizations>(context, AgentChatLocalizations)!;
  }

  // 对话列表页面
  String get conversationListTitle => 'AI 对话';
  String get groupManagement => '分组管理';
  String get editGroup => '编辑分组';
  String get addGroup => '添加分组';
  String get addChannel => '添加频道';
  String get create => '创建';
  String get editConversation => '编辑会话';
  String get confirmDelete => '确认删除';
  String get delete => '删除';
  String get selectCreateType => '选择要创建的类型';
  String get channel => '频道';
  String get channelDescription => '创建新的对话频道';
  String get group => '分组';
  String get groupDescription => '创建新的分组分类';
  String get clear => '清除';

  // 聊天页面
  String get selectAgent => '选择Agent';
  String get createNewChat => '创建新聊天';
  String get tokenStatistics => 'Token统计';
  String get close => '关闭';
  String get conversationSettings => '会话设置';
  String get useGlobalSettings => '使用全局设置';
  String get custom => '自定义';
  String get save => '保存';
  String get cancel => '取消';
  String get confirmClear => '确认清空';
  String get confirmClearTools => '确定要清空所有选中的工具吗？';
  String get confirmDeleteMessage => '确定要删除这条消息吗？';
  String get editMessage => '编辑消息';
  String get toolExecutionResult => '工具执行结果';
  String get image => '图片';
  String get document => '文档';

  // 工具模板页面
  String get toolTemplate => '工具模板';
  String get selectTagFilter => '选择标签过滤';
  String get use => '使用';
  String get deleteConfirm => '删除确认';
  String get reset => '重置';
  String get confirm => '确定';

  // 工具管理页面
  String get toolManagement => '工具管理';
  String get selectPlugin => '选择插件';
  String get confirmImport => '确认导入';
  String get importConfigOverride => '导入配置将覆盖现有配置，是否继续？';
  String get confirmRestoreDefault => '确认恢复默认';
  String get restoreDefaultDescription => '此操作将删除所有自定义配置，恢复到默认配置。是否继续？';
  String get restoreDefault => '恢复默认';
  String get all => '全部';
  String get disabledTools => '已禁用的工具';
  String get enableAll => '全部启用';
  String get confirmEnableAll => '确认全部启用';

  // 设置页面
  String get agentChatSettings => 'Agent Chat 设置';
  String get prioritizeToolTemplate => '优先使用工具模版';
  String get prioritizeToolTemplateDescription => '启用后，AI将优先使用预定义的工具模板执行任务';
  String get enableBackgroundService => '启用后台服务';
  String get enableBackgroundServiceDescription => '切换到其他应用后继续接收AI回复。会显示前台通知以保持服务运行。';
  String get showTokenConsumption => '显示Token消耗';
  String get showTokenConsumptionDescription => '在通知中实时显示输入/输出token数量和总消耗。';
  String get testConfiguration => '测试配置';
  String get saveSettings => '保存设置';

  // 配置对话框
  String get configuration => '配置';
  String get advancedConfiguration => '高级配置';
  String get confirmSave => '确认保存';
  String get confirmSaveDescription => '确定要保存配置吗？';
  String get copyResult => '复制结果';
  String get executeAgain => '重新执行此步骤';

  // 新增的硬编码文本
  String initializationFailed(String error) => '初始化失败: $error';
  String get return => '返回';

  // 消息操作
  String get copy => '复制';
  String get edit => '编辑';
  String get regenerate => '重新生成';
  String get saveTool => '保存工具';
  String get reExecuteTool => '重新执行工具';
  String get viewDetails => '查看详情';
  String get deleteTask => '删除任务';
  String confirmDeleteTask(String taskName) => '确定要删除这个任务吗？';
  String get send => '发送';

  // 工具相关
  String get addTool => '添加工具';
  String get importConfig => '导入配置';
  String get exportConfig => '导出配置';
  String get noToolConfig => '暂无工具配置';
  String get allToolsEnabled => '所有工具都已启用！';
  String confirmEnableAllTools(int count) => '确定要启用所有 $count 个已禁用的工具吗？';
  String get enableTool => '启用工具';
  String get disableToolWarning => '禁用后该工具将不会提供给AI使用';
  String get addParameter => '添加参数';
  String get noParametersClickToAdd => '暂无参数，点击上方按钮添加';
  String get optionalParameter => '可选参数';
  String get addExample => '添加示例';
  String get noExamplesClickToAdd => '暂无示例，点击上方按钮添加';
  String get test => '测试';
  String get executingJSCode => '正在执行 JS 代码...';
  String confirmDeleteTool(String toolId) => '确定要删除工具 "$toolId" 吗？';
  String get deleteConfirmation => '删除确认';
  String confirmDeleteTemplate(String templateName) => '确定要删除工具模板"$templateName"吗？';
  String get resetConfirmation => '重置确认';
  String get reset => '重置';
  String get resettingDefaultTemplates => '正在重置默认模板...';

  // 创建对话框
  String get selectTypeToCreate => '选择要创建的类型';
  String get createNewConversationChannel => '创建新的对话频道';
  String get createNewGroupCategory => '创建新的分组分类';

  // 空状态
  String get loadingToolTemplates => '正在加载工具模板...';
  String get noToolTemplates => '暂无工具模板';
  String get noChannels => '暂无频道';
  String get noGroups => '暂无分组';
  String get noMessages => '暂无消息';
  String get emptyConversationHistory => '空白的对话历史';
}

class _AgentChatLocalizationsDelegate
    extends LocalizationsDelegate<AgentChatLocalizations> {
  const _AgentChatLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AgentChatLocalizations> load(Locale locale) async {
    return AgentChatLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AgentChatLocalizations> old) => false;
}