import 'dart:ui';

import 'agent_chat_localizations.dart';

class AgentChatLocalizationsEn extends AgentChatLocalizations {
  const AgentChatLocalizationsEn() : super(const Locale('en'));

  // 对话列表页面
  @override
  String get conversationListTitle => 'AI Chat';
  @override
  String get groupManagement => 'Group Management';
  @override
  String get editGroup => 'Edit Group';
  @override
  String get addGroup => 'Add Group';
  @override
  String get addChannel => 'Add Channel';
  @override
  String get create => 'Create';
  @override
  String get editConversation => 'Edit Conversation';
  @override
  String get confirmDelete => 'Confirm Delete';
  @override
  String get delete => 'Delete';
  @override
  String get selectCreateType => 'Select Type to Create';
  @override
  String get channel => 'Channel';
  @override
  String get channelDescription => 'Create a new conversation channel';
  @override
  String get group => 'Group';
  @override
  String get groupDescription => 'Create a new group category';
  @override
  String get clear => 'Clear';

  // 聊天页面
  @override
  String get selectAgent => 'Select Agent';
  @override
  String get createNewChat => 'Create New Chat';
  @override
  String get tokenStatistics => 'Token Statistics';
  @override
  String get close => 'Close';
  @override
  String get conversationSettings => 'Conversation Settings';
  @override
  String get useGlobalSettings => 'Use Global Settings';
  @override
  String get custom => 'Custom';
  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirmClear => 'Confirm Clear';
  @override
  String get confirmClearTools =>
      'Are you sure you want to clear all selected tools?';
  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to delete this message?';
  @override
  String get editMessage => 'Edit Message';
  @override
  String get toolExecutionResult => 'Tool Execution Result';
  @override
  String get image => 'Image';
  @override
  String get document => 'Document';

  // 工具模板页面
  @override
  String get toolTemplate => 'Tool Templates';
  @override
  String get selectTagFilter => 'Select Tag Filter';
  @override
  String get use => 'Use';
  @override
  String get deleteConfirm => 'Delete Confirmation';
  @override
  String get reset => 'Reset';
  @override
  String get confirm => 'Confirm';

  // 工具管理页面
  @override
  String get toolManagement => 'Tool Management';
  @override
  String get selectPlugin => 'Select Plugin';
  @override
  String get confirmImport => 'Confirm Import';
  @override
  String get importConfigOverride =>
      'Import configuration will override existing configuration. Continue?';
  @override
  String get confirmRestoreDefault => 'Confirm Restore Default';
  @override
  String get restoreDefaultDescription =>
      'This operation will delete all custom configurations and restore to default settings. Continue?';
  @override
  String get restoreDefault => 'Restore Default';
  @override
  String get all => 'All';
  @override
  String get disabledTools => 'Disabled Tools';
  @override
  String get enableAll => 'Enable All';
  @override
  String get confirmEnableAll => 'Confirm Enable All';

  // 设置页面
  @override
  String get agentChatSettings => 'Agent Chat Settings';
  @override
  String get prioritizeToolTemplate => 'Prioritize Tool Templates';
  @override
  String get prioritizeToolTemplateDescription =>
      'When enabled, AI will prioritize using predefined tool templates to execute tasks';
  @override
  String get enableBackgroundService => 'Enable Background Service';
  @override
  String get enableBackgroundServiceDescription =>
      'Continue receiving AI replies after switching to other apps. Will show foreground notification to keep the service running.';
  @override
  String get showTokenConsumption => 'Show Token Consumption';
  @override
  String get showTokenConsumptionDescription =>
      'Display input/output token count and total consumption in real-time notifications.';
  @override
  String get testConfiguration => 'Test Configuration';
  @override
  String get saveSettings => 'Save Settings';

  // 配置对话框
  @override
  String get configuration => 'Configuration';
  @override
  String get advancedConfiguration => 'Advanced Configuration';
  @override
  String get confirmSave => 'Confirm Save';
  @override
  String get confirmSaveDescription =>
      'Are you sure you want to save the configuration?';
  @override
  String get copyResult => 'Copy Result';
  @override
  String get executeAgain => 'Execute This Step Again';

  // 新增的硬编码文本
  @override
  String initializationFailed(String error) => 'Initialization failed: $error';
  @override
  String get goBack => 'Return';

  // 消息操作
  @override
  String get copy => 'Copy';
  @override
  String get edit => 'Edit';
  @override
  String get regenerate => 'Regenerate';
  @override
  String get saveTool => 'Save Tool';
  @override
  String get reExecuteTool => 'Re-execute Tool';
  @override
  String get viewDetails => 'View Details';
  @override
  String get deleteTask => 'Delete Task';
  @override
  String confirmDeleteTask(String taskName) => 'Are you sure to delete this task?';
  @override
  String get send => 'Send';

  // 工具相关
  @override
  String get addTool => 'Add Tool';
  @override
  String get importConfig => 'Import Config';
  @override
  String get exportConfig => 'Export Config';
  @override
  String get noToolConfig => 'No Tool Config';
  @override
  String get allToolsEnabled => 'All tools are enabled!';
  @override
  String confirmEnableAllTools(int count) => 'Are you sure to enable all $count disabled tools?';
  @override
  String get enableTool => 'Enable Tool';
  @override
  String get disableToolWarning => 'After disabling, this tool will not be available to AI';
  @override
  String get addParameter => 'Add Parameter';
  @override
  String get noParametersClickToAdd => 'No parameters, click button above to add';
  @override
  String get optionalParameter => 'Optional Parameter';
  @override
  String get addExample => 'Add Example';
  @override
  String get noExamplesClickToAdd => 'No examples, click button above to add';
  @override
  String get test => 'Test';
  @override
  String get executingJSCode => 'Executing JS code...';
  @override
  String confirmDeleteTool(String toolId) => 'Are you sure to delete tool "$toolId"?';
  @override
  String get deleteConfirmation => 'Delete Confirmation';
  @override
  String confirmDeleteTemplate(String templateName) => 'Are you sure to delete tool template "$templateName"?';
  @override
  String get resetConfirmation => 'Reset Confirmation';
  @override
  String get resettingDefaultTemplates => 'Resetting default templates...';

  // 创建对话框
  @override
  String get selectTypeToCreate => 'Select Type to Create';
  @override
  String get createNewConversationChannel => 'Create a new conversation channel';
  @override
  String get createNewGroupCategory => 'Create a new group category';

  // 分组相关
  @override
  String confirmDeleteGroup(String groupName) => 'Are you sure to delete group "$groupName"?\\n\\nThis operation will also clear the filter state of this group.';
  @override
  String get aiChat => 'AI Chat';

  // 插件信息
  @override
  String pluginInfo(String pluginId, int enabledCount, int totalCount) => '$pluginId ($enabledCount/$totalCount)';

  // 确认删除会话
  @override
  String confirmDeleteConversation(String title) => 'Are you sure to delete conversation "$title"?\\n\\nThis operation will delete all messages and cannot be undone.';

  // 空状态
  @override
  String get loadingToolTemplates => 'Loading tool templates...';
  @override
  String get noToolTemplates => 'No tool templates';
  @override
  String get noChannels => 'No channels';
  @override
  String get noGroups => 'No groups';
  @override
  String get noMessages => 'No messages';
  @override
  String get emptyConversationHistory => 'Empty conversation history';
}
