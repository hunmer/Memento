import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:logging/logging.dart';

/// 频道消息小组件服务
///
/// 负责将频道数据同步到原生桌面小组件
class ChatWidgetService {
  static final Logger _logger = Logger('ChatWidgetService');
  static const int _maxRecentChannels = 3; // 小组件最多显示3个频道

  /// 更新小组件数据
  static Future<void> updateWidget() async {
    try {
      // home_widget 插件只支持 Android 和 iOS 平台
      if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
        _logger.info('跳过小组件更新（当前平台不支持 home_widget 插件）');
        return;
      }

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

      // 更新小组件
      await HomeWidget.updateWidget(
        androidName: 'ChatQuickWidgetProvider', // 对应 Android AppWidgetProvider 类名
        iOSName: 'ChatQuickWidget', // 对应 iOS Widget 名称
      );

      _logger.info('频道小组件已更新: ${recentChannels.length} 个频道');
    } catch (e, stack) {
      _logger.severe('更新频道小组件失败', e, stack);
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
    try {
      // home_widget 插件只支持 Android 和 iOS 平台
      if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
        _logger.info('跳过获取小组件数据（当前平台不支持 home_widget 插件）');
        return null;
      }

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
    // home_widget 插件只支持 Android 和 iOS 平台
    if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
      _logger.info('跳过注册小组件点击监听（当前平台不支持 home_widget 插件）');
      return;
    }

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
  }

  /// 初始化小组件
  static Future<void> initialize() async {
    try {
      // home_widget 插件只支持 Android 和 iOS 平台
      if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
        _logger.info('跳过小组件初始化（当前平台不支持 home_widget 插件）');
        return;
      }

      // 只在 iOS 平台上设置 App Group ID
      // setAppGroupId 只在 iOS 上有效，在 Android/Web/Windows 上会抛出 MissingPluginException
      // 使用 UniversalPlatform 检查平台类型
      if (UniversalPlatform.isIOS) {
        await HomeWidget.setAppGroupId('group.github.hunmer.memento'); // iOS App Group
      }

      // 初次更新小组件
      await updateWidget();

      _logger.info('频道小组件服务已初始化');
    } catch (e, stack) {
      _logger.severe('初始化频道小组件服务失败', e, stack);
    }
  }
}
