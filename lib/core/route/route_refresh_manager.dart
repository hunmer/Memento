import 'package:flutter/foundation.dart';

import '../event/event_manager.dart';
import '../plugin_manager.dart';
import '../plugin_base.dart';
import 'route_history_manager.dart';

/// 路由刷新管理器
///
/// 负责:
/// - 根据文件路径判断对应的插件
/// - 主动调用插件的 refreshData() 方法重新加载数据
/// - 检查当前路由是否匹配
/// - 触发插件刷新事件
class RouteRefreshManager {
  static final RouteRefreshManager _instance = RouteRefreshManager._internal();
  factory RouteRefreshManager() => _instance;
  RouteRefreshManager._internal();

  static const String _tag = 'RouteRefreshManager';

  PluginManager? _pluginManager;

  /// 防抖：记录最近刷新时间
  final Map<String, DateTime> _lastRefreshTimes = {};

  /// 防抖间隔（毫秒）
  static const int _debounceIntervalMs = 500;

  /// 设置插件管理器
  void setPluginManager(PluginManager pluginManager) {
    _pluginManager = pluginManager;
  }

  /// 文件路径前缀 -> 插件ID 映射
  static const Map<String, String> _fileToPlugin = {
    'diary/': 'diary',
    'chat/': 'chat',
    'notes/': 'notes',
    'todo/': 'todo',
    'activity/': 'activity',
    'bill/': 'bill',
    'tracker/': 'tracker',
    'goods/': 'goods',
    'contact/': 'contact',
    'habits/': 'habits',
    'checkin/': 'checkin',
    'calendar/': 'calendar',
    'calendar_album/': 'calendar_album',
    'timer/': 'timer',
    'database/': 'database',
    'day/': 'day',
    'nodes/': 'nodes',
    'store/': 'store',
  };

  /// 文件同步完成后触发刷新
  Future<void> onFileSynced(String filePath) async {
    final pluginId = _getPluginForFile(filePath);
    if (pluginId == null) {
      _log('未找到文件对应的插件: $filePath');
      return;
    }

    // 防抖检查
    final now = DateTime.now();
    final lastRefresh = _lastRefreshTimes[pluginId];
    if (lastRefresh != null) {
      final diff = now.difference(lastRefresh).inMilliseconds;
      if (diff < _debounceIntervalMs) {
        _log('防抖：跳过刷新 $pluginId (${diff}ms < ${_debounceIntervalMs}ms)');
        return;
      }
    }
    _lastRefreshTimes[pluginId] = now;

    // 1. 主动调用插件的 refreshData() 方法
    bool refreshSuccess = false;
    if (_pluginManager != null) {
      final plugin = _pluginManager!.getPlugin(pluginId);
      if (plugin != null) {
        if (plugin.supportsFileRefresh(filePath)) {
          try {
            refreshSuccess = await plugin.refreshData(
              PluginRefreshDataArgs(
                filePath: filePath,
                source: 'sync',
              ),
            );
            _log('插件数据刷新${refreshSuccess ? "成功" : "失败"}: $pluginId');
          } catch (e) {
            _log('插件数据刷新异常: $pluginId, 错误: $e');
          }
        } else {
          _log('插件不支持该文件的刷新: $filePath');
        }
      }
    }

    // 2. 检查当前路由是否匹配，如果在插件页面内则触发 UI 刷新事件
    if (_isCurrentRoute(pluginId)) {
      _log('当前路由匹配，触发 UI 刷新事件: $pluginId');
      _triggerRefresh(pluginId, refreshSuccess);
    } else {
      _log('当前路由不匹配，跳过 UI 刷新事件: $pluginId');
    }
  }

  /// 根据文件路径获取对应的插件ID
  String? _getPluginForFile(String filePath) {
    for (final entry in _fileToPlugin.entries) {
      if (filePath.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// 检查当前路由是否匹配指定插件
  bool _isCurrentRoute(String pluginId) {
    // 从路由历史管理器获取当前路由上下文
    final currentContext = RouteHistoryManager.getCurrentContext();
    if (currentContext == null) {
      _log('无法获取当前路由');
      return false;
    }

    final currentRoute = currentContext.pageId;

    // 检查路由是否包含插件ID
    return currentRoute.contains('/$pluginId') ||
           currentRoute == pluginId ||
           currentRoute.endsWith('/$pluginId');
  }

  /// 触发插件刷新
  void _triggerRefresh(String pluginId, bool refreshSuccess) {
    // 广播插件刷新事件
    EventManager.instance.broadcast(
      '${pluginId}_refresh',
      PluginRefreshArgs(pluginId: pluginId, success: refreshSuccess),
    );

    // 同时广播通用的数据更新事件
    EventManager.instance.broadcast(
      'sync_data_updated',
      SyncDataUpdatedArgs(filePath: '', source: 'websocket', pluginId: pluginId),
    );

    _log('已触发刷新事件: $pluginId');
  }

  /// 获取文件对应的插件ID（公开方法）
  String? getPluginForFile(String filePath) {
    return _getPluginForFile(filePath);
  }

  /// 检查路由是否匹配（公开方法）
  bool isCurrentRoute(String pluginId) {
    return _isCurrentRoute(pluginId);
  }

  /// 输出日志
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('$_tag: $message');
    }
  }
}

/// 插件刷新事件参数
class PluginRefreshArgs extends EventArgs {
  final String pluginId;
  final bool success;

  PluginRefreshArgs({
    required this.pluginId,
    this.success = false,
  }) : super('plugin_refresh');
}

/// 同步数据更新事件参数
class SyncDataUpdatedArgs extends EventArgs {
  final String filePath;
  final String source;
  final String? pluginId;

  SyncDataUpdatedArgs({
    required this.filePath,
    required this.source,
    this.pluginId,
  }) : super('${pluginId ?? 'sync'}_data_updated');
}
