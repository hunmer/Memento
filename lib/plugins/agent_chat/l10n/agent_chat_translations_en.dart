/// Agent Chat plugin English translations
const Map<String, String> agentChatTranslationsEn = {
  // Conversation list page
  'agent_chat_conversationListTitle': 'AI Chat',
  'agent_chat_groupManagement': 'Group Management',
  'agent_chat_editGroup': 'Edit Group',
  'agent_chat_addGroup': 'Add Group',
  'agent_chat_addChannel': 'Add Channel',
  'agent_chat_create': 'Create',
  'agent_chat_editConversation': 'Edit Conversation',
  'agent_chat_confirmDelete': 'Confirm Delete',
  'agent_chat_delete': 'Delete',
  'agent_chat_selectCreateType': 'Select Type to Create',
  'agent_chat_channel': 'Channel',
  'agent_chat_channelDescription': 'Create a new conversation channel',
  'agent_chat_group': 'Group',
  'agent_chat_groupDescription': 'Create a new group category',
  'agent_chat_clear': 'Clear',

  // Chat page
  'agent_chat_selectAgent': 'Select Agent',
  'agent_chat_createNewChat': 'Create New Chat',
  'agent_chat_tokenStatistics': 'Token Statistics',
  'agent_chat_close': 'Close',
  'agent_chat_conversationSettings': 'Conversation Settings',
  'agent_chat_useGlobalSettings': 'Use Global Settings',
  'agent_chat_custom': 'Custom',
  'agent_chat_save': 'Save',
  'agent_chat_cancel': 'Cancel',
  'agent_chat_confirmClear': 'Confirm Clear',
  'agent_chat_confirmClearTools': 'Are you sure you want to clear all selected tools?',
  'agent_chat_confirmDeleteMessage': 'Are you sure you want to delete this message?',
  'agent_chat_editMessage': 'Edit Message',
  'agent_chat_toolExecutionResult': 'Tool Execution Result',
  'agent_chat_image': 'Image',
  'agent_chat_document': 'Document',

  // Tool template page
  'agent_chat_toolTemplate': 'Tool Templates',
  'agent_chat_selectTagFilter': 'Select Tag Filter',
  'agent_chat_use': 'Use',
  'agent_chat_deleteConfirm': 'Delete Confirmation',
  'agent_chat_reset': 'Reset',
  'agent_chat_confirm': 'Confirm',

  // Tool management page
  'agent_chat_toolManagement': 'Tool Management',
  'agent_chat_selectPlugin': 'Select Plugin',
  'agent_chat_confirmImport': 'Confirm Import',
  'agent_chat_importConfigOverride': 'Import configuration will override existing configuration. Continue?',
  'agent_chat_confirmRestoreDefault': 'Confirm Restore Default',
  'agent_chat_restoreDefaultDescription': 'This operation will delete all custom configurations and restore to default settings. Continue?',
  'agent_chat_restoreDefault': 'Restore Default',
  'agent_chat_all': 'All',
  'agent_chat_disabledTools': 'Disabled Tools',
  'agent_chat_enableAll': 'Enable All',
  'agent_chat_confirmEnableAll': 'Confirm Enable All',

  // Settings page
  'agent_chat_agentChatSettings': 'Agent Chat Settings',
  'agent_chat_prioritizeToolTemplate': 'Prioritize Tool Templates',
  'agent_chat_prioritizeToolTemplateDescription': 'When enabled, AI will prioritize using predefined tool templates to execute tasks',
  'agent_chat_enableBackgroundService': 'Enable Background Service',
  'agent_chat_enableBackgroundServiceDescription': 'Continue receiving AI replies after switching to other apps. Will show foreground notification to keep the service running.',
  'agent_chat_showTokenConsumption': 'Show Token Consumption',
  'agent_chat_showTokenConsumptionDescription': 'Display input/output token count and total consumption in real-time notifications.',
  'agent_chat_testConfiguration': 'Test Configuration',
  'agent_chat_saveSettings': 'Save Settings',

  // Configuration dialog
  'agent_chat_configuration': 'Configuration',
  'agent_chat_advancedConfiguration': 'Advanced Configuration',
  'agent_chat_confirmSave': 'Confirm Save',
  'agent_chat_confirmSaveDescription': 'Are you sure you want to save the configuration?',
  'agent_chat_copyResult': 'Copy Result',
  'agent_chat_executeAgain': 'Execute This Step Again',

  // New hardcoded text
  'agent_chat_initializationFailed': 'Initialization failed: @error',
  'agent_chat_goBack': 'Return',

  // Message operations
  'agent_chat_copy': 'Copy',
  'agent_chat_edit': 'Edit',
  'agent_chat_regenerate': 'Regenerate',
  'agent_chat_saveTool': 'Save Tool',
  'agent_chat_reExecuteTool': 'Re-execute Tool',
  'agent_chat_viewDetails': 'View Details',
  'agent_chat_deleteTask': 'Delete Task',
  'agent_chat_confirmDeleteTask': 'Are you sure to delete this task?',
  'agent_chat_send': 'Send',

  // Tool related
  'agent_chat_addTool': 'Add Tool',
  'agent_chat_importConfig': 'Import Config',
  'agent_chat_exportConfig': 'Export Config',
  'agent_chat_noToolConfig': 'No Tool Config',
  'agent_chat_allToolsEnabled': 'All tools are enabled!',
  'agent_chat_confirmEnableAllTools': 'Are you sure to enable all @count disabled tools?',
  'agent_chat_enableTool': 'Enable Tool',
  'agent_chat_disableToolWarning': 'After disabling, this tool will not be available to AI',
  'agent_chat_addParameter': 'Add Parameter',
  'agent_chat_noParametersClickToAdd': 'No parameters, click button above to add',
  'agent_chat_optionalParameter': 'Optional Parameter',
  'agent_chat_addExample': 'Add Example',
  'agent_chat_noExamplesClickToAdd': 'No examples, click button above to add',
  'agent_chat_test': 'Test',
  'agent_chat_executingJSCode': 'Executing JS code...',
  'agent_chat_confirmDeleteTool': 'Are you sure to delete tool "@toolId"?',
  'agent_chat_deleteConfirmation': 'Delete Confirmation',
  'agent_chat_confirmDeleteTemplate': 'Are you sure to delete tool template "@templateName"?',
  'agent_chat_resetConfirmation': 'Reset Confirmation',
  'agent_chat_resettingDefaultTemplates': 'Resetting default templates...',

  // Create dialog
  'agent_chat_selectTypeToCreate': 'Select Type to Create',
  'agent_chat_createNewConversationChannel': 'Create a new conversation channel',
  'agent_chat_createNewGroupCategory': 'Create a new group category',
  'agent_chat_confirmDeleteGroup': 'Are you sure to delete group "@groupName"?\n\nThis operation will also clear the filter state of this group.',
  'agent_chat_aiChat': 'AI Chat',

  // Plugin info
  'agent_chat_pluginInfo': '@pluginId (@enabledCount/@totalCount)',

  // Confirm delete conversation
  'agent_chat_confirmDeleteConversation': 'Are you sure to delete conversation "@title"?\n\nThis operation will delete all messages and cannot be undone.',

  // Empty states
  'agent_chat_loadingToolTemplates': 'Loading tool templates...',
  'agent_chat_noToolTemplates': 'No tool templates',
  'agent_chat_noChannels': 'No channels',
  'agent_chat_noGroups': 'No groups',
  'agent_chat_noMessages': 'No messages',
  'agent_chat_emptyConversationHistory': 'Empty conversation history',

  // Widget Home Strings
  'agent_chat_pluginName': 'Agent Chat',
  'agent_chat_name': 'Agent Chat',
  'agent_chat_description': 'Quick access to Agent Chat',
  'agent_chat_overview': 'Agent Chat Overview',
  'agent_chat_overviewDescription': 'Display conversation statistics',
  'agent_chat_totalConversations': 'Total Conversations',
  'agent_chat_unreadMessages': 'Unread Messages',
  'agent_chat_totalGroups': 'Total Groups',
  'agent_chat_loadFailed': 'Load Failed',

  // Selector Widget
  'agent_chat_conversationSelectorName': 'Conversation Selector',
  'agent_chat_conversationSelectorDesc': 'Select a conversation channel',
  'agent_chat_selectConversation': 'Select Conversation',
  'agent_chat_conversationQuickAccess': 'AI Channel Quick Access',
  'agent_chat_conversationQuickAccessDesc': 'Quick access to a specific AI conversation channel',
  'agent_chat_clickToEnter': 'Click to enter',
  'agent_chat_justNow': 'Just now',
  'agent_chat_minutesAgo': '@count minutes ago',
  'agent_chat_hoursAgo': '@count hours ago',
  'agent_chat_daysAgo': '@count days ago',

  // Interface search
  'agent_chat_searchPlaceholder': 'Search conversations...',
};
