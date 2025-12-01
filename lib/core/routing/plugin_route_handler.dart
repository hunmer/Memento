import 'package:flutter/material.dart';

/// 插件路由处理器基类
/// 每个插件可以实现自己的路由处理逻辑
abstract class PluginRouteHandler {
  /// 插件 ID
  String get pluginId;

  /// 处理路由请求
  ///
  /// 如果能处理该路由，返回对应的 Route；否则返回 null
  ///
  /// [settings] 路由设置，包含路由名称和参数
  Route<dynamic>? handleRoute(RouteSettings settings);

  /// 创建无动画过渡的路由
  Route<dynamic> createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
      transitionDuration: const Duration(milliseconds: 0),
      reverseTransitionDuration: const Duration(milliseconds: 0),
    );
  }
}
