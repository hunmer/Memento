/// Agent Chat插件中文翻译
const Map<String, String> agentChatTranslationsZh = {
  // 对话列表页面
  'agent_chat_conversationListTitle': 'AI 对话',
  'agent_chat_groupManagement': '分组管理',
  'agent_chat_editGroup': '编辑分组',
  'agent_chat_addGroup': '添加分组',
  'agent_chat_addChannel': '添加频道',
  'agent_chat_create': '创建',
  'agent_chat_editConversation': '编辑会话',
  'agent_chat_confirmDelete': '确认删除',
  'agent_chat_delete': '删除',
  'agent_chat_selectCreateType': '选择要创建的类型',
  'agent_chat_channel': '频道',
  'agent_chat_channelDescription': '创建新的对话频道',
  'agent_chat_group': '分组',
  'agent_chat_groupDescription': '创建新的分组分类',
  'agent_chat_clear': '清除',

  // 聊天页面
  'agent_chat_selectAgent': '选择Agent',
  'agent_chat_createNewChat': '创建新聊天',
  'agent_chat_tokenStatistics': 'Token统计',
  'agent_chat_close': '关闭',
  'agent_chat_conversationSettings': '会话设置',
  'agent_chat_useGlobalSettings': '使用全局设置',
  'agent_chat_custom': '自定义',
  'agent_chat_save': '保存',
  'agent_chat_cancel': '取消',
  'agent_chat_confirmClear': '确认清空',
  'agent_chat_confirmClearTools': '确定要清空所有选中的工具吗？',
  'agent_chat_confirmDeleteMessage': '确定要删除这条消息吗？',
  'agent_chat_editMessage': '编辑消息',
  'agent_chat_toolExecutionResult': '工具执行结果',
  'agent_chat_image': '图片',
  'agent_chat_document': '文档',

  // 工具模板页面
  'agent_chat_toolTemplate': '工具模板',
  'agent_chat_selectTagFilter': '选择标签过滤',
  'agent_chat_use': '使用',
  'agent_chat_deleteConfirm': '删除确认',
  'agent_chat_reset': '重置',
  'agent_chat_confirm': '确定',

  // 工具管理页面
  'agent_chat_toolManagement': '工具管理',
  'agent_chat_selectPlugin': '选择插件',
  'agent_chat_confirmImport': '确认导入',
  'agent_chat_importConfigOverride': '导入配置将覆盖现有配置,是否继续?',
  'agent_chat_confirmRestoreDefault': '确认恢复默认',
  'agent_chat_restoreDefaultDescription': '此操作将删除所有自定义配置,恢复到默认配置。是否继续?',
  'agent_chat_restoreDefault': '恢复默认',
  'agent_chat_all': '全部',
  'agent_chat_disabledTools': '已禁用的工具',
  'agent_chat_enableAll': '全部启用',
  'agent_chat_confirmEnableAll': '确认全部启用',

  // 设置页面
  'agent_chat_agentChatSettings': 'Agent Chat 设置',
  'agent_chat_prioritizeToolTemplate': '优先使用工具模版',
  'agent_chat_prioritizeToolTemplateDescription': '启用后,AI将优先使用预定义的工具模板执行任务',
  'agent_chat_enableBackgroundService': '启用后台服务',
  'agent_chat_enableBackgroundServiceDescription': '切换到其他应用后继续接收AI回复。会显示前台通知以保持服务运行。',
  'agent_chat_showTokenConsumption': '显示Token消耗',
  'agent_chat_showTokenConsumptionDescription': '在通知中实时显示输入/输出token数量和总消耗。',
  'agent_chat_testConfiguration': '测试配置',
  'agent_chat_saveSettings': '保存设置',

  // 配置对话框
  'agent_chat_configuration': '配置',
  'agent_chat_advancedConfiguration': '高级配置',
  'agent_chat_confirmSave': '确认保存',
  'agent_chat_confirmSaveDescription': '确定要保存配置吗?',
  'agent_chat_copyResult': '复制结果',
  'agent_chat_executeAgain': '重新执行此步骤',

  // 新增的硬编码文本
  'agent_chat_initializationFailed': '初始化失败: @error',
  'agent_chat_goBack': '返回',

  // 消息操作
  'agent_chat_copy': '复制',
  'agent_chat_edit': '编辑',
  'agent_chat_regenerate': '重新生成',
  'agent_chat_saveTool': '保存工具',
  'agent_chat_reExecuteTool': '重新执行工具',
  'agent_chat_viewDetails': '查看详情',
  'agent_chat_deleteTask': '删除任务',
  'agent_chat_confirmDeleteTask': '确定要删除这个任务吗?',
  'agent_chat_send': '发送',

  // 工具相关
  'agent_chat_addTool': '添加工具',
  'agent_chat_importConfig': '导入配置',
  'agent_chat_exportConfig': '导出配置',
  'agent_chat_noToolConfig': '暂无工具配置',
  'agent_chat_allToolsEnabled': '所有工具都已启用!',
  'agent_chat_confirmEnableAllTools': '确定要启用所有 @count 个已禁用的工具吗?',
  'agent_chat_enableTool': '启用工具',
  'agent_chat_disableToolWarning': '禁用后该工具将不会提供给AI使用',
  'agent_chat_addParameter': '添加参数',
  'agent_chat_noParametersClickToAdd': '暂无参数,点击上方按钮添加',
  'agent_chat_optionalParameter': '可选参数',
  'agent_chat_addExample': '添加示例',
  'agent_chat_noExamplesClickToAdd': '暂无示例,点击上方按钮添加',
  'agent_chat_test': '测试',
  'agent_chat_executingJSCode': '正在执行 JS 代码...',
  'agent_chat_confirmDeleteTool': '确定要删除工具 "@toolId" 吗?',
  'agent_chat_deleteConfirmation': '删除确认',
  'agent_chat_confirmDeleteTemplate': '确定要删除工具模板"@templateName"吗?',
  'agent_chat_resetConfirmation': '重置确认',
  'agent_chat_resettingDefaultTemplates': '正在重置默认模板...',

  // 创建对话框
  'agent_chat_selectTypeToCreate': '选择要创建的类型',
  'agent_chat_createNewConversationChannel': '创建新的对话频道',
  'agent_chat_createNewGroupCategory': '创建新的分组分类',
  'agent_chat_confirmDeleteGroup': '确定要删除分组 "@groupName" 吗?\n\n此操作将同时清除该分组的筛选状态。',
  'agent_chat_aiChat': 'AI 对话',

  // 插件信息
  'agent_chat_pluginInfo': '@pluginId (@enabledCount/@totalCount)',

  // 确认删除会话
  'agent_chat_confirmDeleteConversation': '确定要删除会话 "@title" 吗?\n\n此操作将同时删除所有消息记录,且不可恢复。',

  // 空状态
  'agent_chat_loadingToolTemplates': '正在加载工具模板...',
  'agent_chat_noToolTemplates': '暂无工具模板',
  'agent_chat_noChannels': '暂无频道',
  'agent_chat_noGroups': '暂无分组',
  'agent_chat_noMessages': '暂无消息',
  'agent_chat_emptyConversationHistory': '空白的对话历史',

  // Widget Home Strings
  'agent_chat_pluginName': 'AI 对话',
  'agent_chat_name': 'AI 对话',
  'agent_chat_description': '快速打开 Agent Chat',
  'agent_chat_overview': 'Agent Chat 概览',
  'agent_chat_overviewDescription': '显示会话统计信息',
  'agent_chat_totalConversations': '会话总数',
  'agent_chat_unreadMessages': '未读消息',
  'agent_chat_totalGroups': '分组总数',
  'agent_chat_loadFailed': '加载失败',

  // 界面搜索
  'agent_chat_searchPlaceholder': '搜索会话...',
};
