import 'package:Memento/core/services/system_widget_service.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:logging/logging.dart';

/// AI 对话小组件服务
///
/// 负责将对话数据同步到原生桌面小组件
class AgentChatWidgetService {
  static final Logger _logger = Logger('AgentChatWidgetService');
  static const int _maxRecentConversations = 3; // 小组件最多显示3个对话

  /// 更新小组件数据
  static Future<void> updateWidget() async {
    // 统一平台检查
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      _logger.fine('Widget not supported on this platform, skipping AgentChat widget update');
      return;
    }

    try {
      final plugin = AgentChatPlugin.instance;
      final conversations = plugin.conversationController.conversations;

      // 获取最近使用的对话
      final recentConversations = _getRecentConversations(conversations);

      // 构建插件小组件数据
      final widgetData = PluginWidgetData(
        pluginId: 'agent_chat',
        pluginName: 'AI对话',
        iconCodePoint: 0xe0b7, // 聊天图标 codePoint (可以根据需要调整)
        colorValue: 0xFF2196F3, // 蓝色主题
        stats: [
          WidgetStatItem(
            id: 'conversation_count',
            label: '对话数',
            value: conversations.length.toString(),
            highlight: true,
          ),
          WidgetStatItem(
            id: 'recent_message',
            label: '最近消息',
            value: recentConversations.isNotEmpty
                ? _truncateMessage(recentConversations.first.lastMessagePreview ?? '暂无消息', 15)
                : '暂无对话',
          ),
        ],
      );

      // 使用系统小组件服务更新
      await SystemWidgetService.instance.updateWidgetData('agent_chat', widgetData);

      _logger.info('AI对话小组件已更新: ${recentConversations.length} 个对话');
    } catch (e, stack) {
      _logger.severe('更新AI对话小组件失败', e, stack);
    }
  }

  /// 获取最近使用的对话
  static List<Conversation> _getRecentConversations(List<Conversation> conversations) {
    // 按最后消息时间排序
    final sorted = List<Conversation>.from(conversations);
    sorted.sort((a, b) {
      return b.lastMessageAt.compareTo(a.lastMessageAt);
    });

    return sorted.take(_maxRecentConversations).toList();
  }

  /// 截断消息文本
  static String _truncateMessage(String message, int maxLength) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  /// 初始化小组件服务
  static Future<void> initialize() async {
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      _logger.fine('Widget not supported on this platform, skipping AgentChatWidgetService initialization');
      return;
    }

    try {
      // 初次更新小组件
      await updateWidget();

      _logger.info('AgentChatWidgetService 已初始化');
    } catch (e, stack) {
      _logger.severe('初始化 AgentChatWidgetService 失败', e, stack);
    }
  }
}
