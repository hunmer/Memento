import 'package:flutter/material.dart';
import 'route_definition.dart';

/// 路由管理器
class RouteManager {
  /// 单例模式
  static final RouteManager _instance = RouteManager._internal();
  factory RouteManager() => _instance;
  RouteManager._internal();

  /// 路由处理器映射表
  final Map<String, RouteHandler> _routeHandlers = {};

  /// 路由处理器映射表（带前缀）
  final Map<String, RouteHandler> _prefixHandlers = {};

  /// 注册路由定义列表
  void registerRoutes(List<RouteDefinition> routeDefinitions) {
    for (final definition in routeDefinitions) {
      _routeHandlers[definition.path] = definition.handler;
    }
  }

  /// 注册前缀路由（用于处理带路径参数的路由）
  /// 例如前缀 '/widgets_gallery' 可以匹配 '/widgets_gallery/xxx'
  void registerPrefixRoutes(String prefix, RouteHandler handler) {
    _prefixHandlers[prefix] = handler;
  }

  /// 处理路由
  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name ?? '/';

    // 1. 精确匹配
    final handler = _routeHandlers[routeName];
    if (handler != null) {
      return handler(settings);
    }

    // 2. 前缀匹配（用于处理子路由）
    for (final entry in _prefixHandlers.entries) {
      if (routeName.startsWith('${entry.key}/')) {
        return entry.value(settings);
      }
    }

    // 3. 未找到路由
    debugPrint('RouteManager: 未找到路由: $routeName');
    return null;
  }

  /// 检查路由是否存在
  bool hasRoute(String path) {
    return _routeHandlers.containsKey(path) ||
        _prefixHandlers.keys.any((prefix) => path.startsWith('$prefix/'));
  }

  /// 获取所有已注册的路由路径（用于调试）
  List<String> get registeredPaths => [
        ..._routeHandlers.keys,
        ..._prefixHandlers.keys.map((p) => '$p/*'),
      ];

  /// 清空所有路由（用于测试）
  void clear() {
    _routeHandlers.clear();
    _prefixHandlers.clear();
  }
}
