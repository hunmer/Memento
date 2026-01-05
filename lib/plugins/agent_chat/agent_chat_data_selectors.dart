part of 'agent_chat_plugin.dart';

/// 数据选择器注册
///
/// 为 agent_chat 插件注册所有数据选择器，允许其他插件或功能
/// 通过选择器界面选择 agent_chat 的数据（如会话）
void _registerDataSelectors() {
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'agent_chat.conversation',
      pluginId: 'agent_chat',
      name: 'agent_chat_conversationSelectorName'.tr,
      description: 'agent_chat_conversationSelectorDesc'.tr,
      icon: Icons.chat_bubble_outline,
      color: color,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'select_conversation',
          title: 'agent_chat_selectConversation'.tr,
          viewType: SelectorViewType.list,
          dataLoader: (previousSelections) async {
            // 加载所有会话
            final conversations = _conversationController?.conversations ?? [];
            return conversations.map((conv) => SelectableItem(
              id: conv.id,
              title: conv.title,
              subtitle: conv.lastMessagePreview ?? '',
              icon: Icons.chat,
              color: conv.isPinned ? Colors.amber : null,
              rawData: {
                'id': conv.id,
                'title': conv.title,
                'agentId': conv.agentId,
                'isPinned': conv.isPinned,
                'lastMessagePreview': conv.lastMessagePreview,
                'lastMessageAt': conv.lastMessageAt.toIso8601String(),
              },
            )).toList();
          },
          isFinalStep: true,
        ),
      ],
    ),
  );
}
