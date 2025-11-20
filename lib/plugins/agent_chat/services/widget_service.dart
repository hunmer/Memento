import 'dart:convert';
import 'package:home_widget/home_widget.dart';
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
    try {
      final plugin = AgentChatPlugin.instance;
      final conversations = plugin.conversationController.conversations;

      // 获取最近使用的对话
      final recentConversations = _getRecentConversations(conversations);

      // 序列化对话数据
      final conversationsData = recentConversations.map((c) => {
        'id': c.id,
        'title': c.title,
        'lastMessage': c.lastMessagePreview ?? '',
        'lastMessageTime': c.lastMessageAt.toIso8601String(),
        'groupName': c.groups.isNotEmpty ? c.groups.first : '',
      }).toList();

      // 保存到 SharedPreferences（Android）/ UserDefaults（iOS）
      await HomeWidget.saveWidgetData('conversations_json', jsonEncode(conversationsData));
      await HomeWidget.saveWidgetData('conversation_count', conversations.length);
      await HomeWidget.saveWidgetData('last_update', DateTime.now().toIso8601String());

      // 更新小组件
      await HomeWidget.updateWidget(
        androidName: 'AgentVoiceWidgetProvider', // 对应 Android AppWidgetProvider 类名
        iOSName: 'AgentVoiceWidget', // 对应 iOS Widget 名称
      );

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

  /// 处理小组件点击事件
  ///
  /// 从 home_widget 回调中获取点击的数据
  static Future<Map<String, String?>?> getWidgetData() async {
    try {
      // 获取小组件传递的数据
      final data = await HomeWidget.getWidgetData<String>('widget_action');
      if (data == null) return null;

      // 解析 JSON 数据
      final Map<String, dynamic> action = jsonDecode(data);
      return action.cast<String, String?>();
    } catch (e) {
      _logger.warning('获取小组件数据失败: $e');
      return null;
    }
  }

  /// 注册小组件点击事件监听
  static void registerWidgetClickListener(Function(String? conversationId) callback) {
    HomeWidget.widgetClicked.listen((uri) {
      if (uri == null) return;

      _logger.info('小组件被点击: $uri');

      // 解析 URI: memento://widget/voice_quick?conversationId=xxx
      if (uri.host == 'widget') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty && pathSegments[0] == 'voice_quick') {
          final conversationId = uri.queryParameters['conversationId'];
          callback(conversationId);
        }
      }
    });
  }

  /// 初始化小组件
  static Future<void> initialize() async {
    try {
      // 设置小组件配置
      await HomeWidget.setAppGroupId('group.github.hunmer.memento'); // iOS App Group

      // 初次更新小组件
      await updateWidget();

      _logger.info('AI对话小组件服务已初始化');
    } catch (e, stack) {
      _logger.severe('初始化AI对话小组件服务失败', e, stack);
    }
  }
}
