import 'package:flutter/material.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/screens/home_screen/home_screen.dart';
import 'package:Memento/screens/settings_screen/settings_screen.dart';

/// 核心屏幕路由注册表
class CoreRoutes implements RouteRegistry {
  @override
  String get name => 'CoreRoutes';

  @override
  List<RouteDefinition> get routes => [
        // 主屏幕
        RouteDefinition(
          path: '/',
          handler: (settings) => RouteHelpers.createRoute(const HomeScreen()),
          description: '主屏幕',
        ),
        RouteDefinition(
          path: 'home',
          handler: (settings) => RouteHelpers.createRoute(const HomeScreen()),
          description: '主屏幕（别名）',
        ),

        // 设置页面
        RouteDefinition(
          path: '/settings',
          handler: (settings) => RouteHelpers.createRoute(const SettingsScreen()),
          description: '设置界面',
        ),
        RouteDefinition(
          path: 'settings',
          handler: (settings) => RouteHelpers.createRoute(const SettingsScreen()),
          description: '设置界面（别名）',
        ),
      ];
}
