import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/core/services/system_widget_service.dart';
import 'package:logging/logging.dart';

/// 频道消息小组件服务
///
/// 负责将频道数据同步到原生桌面小组件
/// 包括:
/// 1. ChatQuickWidget - 快速小组件(显示最近3个频道)
/// 2. ChatWidget - 常规插件小组件(通过 PluginWidgetSyncHelper 管理)
class ChatWidgetService {
  static final Logger _logger = Logger('ChatWidgetService');
  static const int _maxRecentChannels = 3; // 小组件最多显示3个频道

  /// 更新快速小组件(ChatQuickWidget)
  static Future<void> updateWidget() async {
    // 统一平台检查
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      return;
    }

    try {
      final plugin = ChatPlugin.instance;
      final channels = plugin.channelService.channels;

      // 获取最近使用的频道（按最后消息时间排序）
      final recentChannels = _getRecentChannels(channels);

      // 序列化频道数据
      final channelsData = recentChannels.map((c) => {
        'id': c.id,
        'name': c.title,
        'iconCodePoint': c.icon.codePoint,
        'colorValue': c.backgroundColor.value,
        'lastMessage': c.messages.isNotEmpty ? c.messages.last.content : '',
        'unreadCount': 0, // TODO: 实现未读计数
      }).toList();

      // 保存到 SharedPreferences（Android）/ UserDefaults（iOS）
      await HomeWidget.saveWidgetData('channels_json', jsonEncode(channelsData));
      await HomeWidget.saveWidgetData('channel_count', channels.length);
      await HomeWidget.saveWidgetData('last_update', DateTime.now().toIso8601String());

      // 更新快速小组件（使用完整的包名）
      await HomeWidget.updateWidget(
        name: 'ChatQuickWidget',
        qualifiedAndroidName: 'github.hunmer.memento.widgets.quick.ChatQuickWidgetProvider',
        iOSName: 'ChatQuickWidget',
      );

      _logger.info('ChatQuickWidget 已更新: ${recentChannels.length} 个频道');
    } catch (e, stack) {
      _logger.severe('更新 ChatQuickWidget 失败', e, stack);
    }
  }

  /// 获取最近使用的频道
  static List<Channel> _getRecentChannels(List<Channel> channels) {
    // 按最后消息时间排序
    final sorted = List<Channel>.from(channels);
    sorted.sort((a, b) {
      final aTime = a.messages.isNotEmpty
          ? a.messages.last.date
          : DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.messages.isNotEmpty
          ? b.messages.last.date
          : DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return sorted.take(_maxRecentChannels).toList();
  }

  /// 处理小组件点击事件
  ///
  /// 从 home_widget 回调中获取点击的数据
  static Future<Map<String, String?>?> getWidgetData() async {
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      return null;
    }

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
  static void registerWidgetClickListener(Function(String? channelId) callback) {
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      return;
    }

    try {
      HomeWidget.widgetClicked.listen((uri) {
        if (uri == null) return;

        _logger.info('小组件被点击: $uri');

        // 解析 URI: memento://widget/chat?channelId=xxx
        if (uri.host == 'widget') {
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty && pathSegments[0] == 'chat') {
            final channelId = uri.queryParameters['channelId'];
            callback(channelId);
          }
        }
      });
    } catch (e, stack) {
      _logger.warning('注册小组件点击监听失败', e, stack);
    }
  }

  /// 初始化小组件服务
  static Future<void> initialize() async {
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      return;
    }

    try {
      // 初次更新快速小组件
      await updateWidget();

      _logger.info('ChatWidgetService 已初始化');
    } catch (e, stack) {
      _logger.severe('初始化 ChatWidgetService 失败', e, stack);
    }
  }
}
