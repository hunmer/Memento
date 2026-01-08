import 'package:flutter/material.dart';

/// 路由处理器函数类型
typedef RouteHandler = Route<dynamic> Function(RouteSettings settings);

/// 路由定义类
class RouteDefinition {
  /// 路由路径
  final String path;

  /// 路由处理器
  final RouteHandler handler;

  /// 路由描述（用于调试）
  final String? description;

  const RouteDefinition({
    required this.path,
    required this.handler,
    this.description,
  });
}

/// 路由注册接口
abstract class RouteRegistry {
  /// 获取注册的所有路由定义
  List<RouteDefinition> get routes;

  /// 可选：注册表的名称（用于调试）
  String get name => runtimeType.toString();
}
