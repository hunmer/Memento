import 'package:flutter/material.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/diary/diary_plugin.dart';

/// Diary 插件路由注册表
class DiaryRoutes implements RouteRegistry {
  @override
  String get name => 'DiaryRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Diary 主页面
        RouteDefinition(
          path: '/diary',
          handler: (settings) => RouteHelpers.createRoute(
            const DiaryMainView(),
            settings: settings,
          ),
          description: '日记主页面',
        ),
        RouteDefinition(
          path: 'diary',
          handler: (settings) => RouteHelpers.createRoute(
            const DiaryMainView(),
            settings: settings,
          ),
          description: '日记主页面（别名）',
        ),

        // Diary 详情页面（支持通过 date 参数打开指定日期的日记）
        RouteDefinition(
          path: '/diary_detail',
          handler: (settings) {
            DateTime? selectedDate;
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final dateStr = args['date'] as String?;
              if (dateStr != null) {
                try {
                  selectedDate = DateTime.parse(dateStr);
                } catch (e) {
                  debugPrint('解析日期失败: $e');
                }
              }
            }
            return RouteHelpers.createRoute(
              DiaryMainView(initialDate: selectedDate),
              settings: settings,
            );
          },
          description: '日记详情页面',
        ),
        RouteDefinition(
          path: 'diary_detail',
          handler: (settings) {
            DateTime? selectedDate;
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final dateStr = args['date'] as String?;
              if (dateStr != null) {
                try {
                  selectedDate = DateTime.parse(dateStr);
                } catch (e) {
                  debugPrint('解析日期失败: $e');
                }
              }
            }
            return RouteHelpers.createRoute(
              DiaryMainView(initialDate: selectedDate),
              settings: settings,
            );
          },
          description: '日记详情页面（别名）',
        ),
      ];
}
