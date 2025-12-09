import 'package:flutter/material.dart';
import 'package:Memento/core/routing/plugin_route_handler.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/checkin/screens/checkin_item_selector_screen.dart';

/// 打卡插件路由处理器
class CheckinRouteHandler extends PluginRouteHandler {
  @override
  String get pluginId => 'checkin';

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // 处理打卡小组件配置路由
    // 格式: /checkin_item_selector?widgetId={widgetId}
    // 或者 widgetId 通过 settings.arguments 传递
    if (routeName.startsWith('/checkin_item_selector')) {
      return _handleItemSelectorRoute(routeName, settings.arguments);
    }

    // 处理打卡小组件点击路由（已配置状态）
    // 格式: /checkin_item?itemId={itemId}&date={date}
    if (routeName.startsWith('/checkin_item')) {
      return _handleItemClickRoute(routeName, settings.arguments);
    }

    return null;
  }

  /// 处理打卡项选择器路由
  Route<dynamic> _handleItemSelectorRoute(String routeName, Object? arguments) {
    int? widgetId;

    // 优先从 arguments 中获取 widgetId（来自 main.dart 的路由处理）
    if (arguments is Map<String, dynamic>) {
      final widgetIdValue = arguments['widgetId'];
      if (widgetIdValue is int) {
        widgetId = widgetIdValue;
      } else if (widgetIdValue is String) {
        widgetId = int.tryParse(widgetIdValue);
      }
    } else if (arguments is Map<String, String>) {
      final widgetIdStr = arguments['widgetId'];
      widgetId = widgetIdStr != null ? int.tryParse(widgetIdStr) : null;
    }

    // 备用：从 URI 中解析 widgetId
    if (widgetId == null) {
      final uri = Uri.parse(routeName);
      final widgetIdStr = uri.queryParameters['widgetId'];
      widgetId = widgetIdStr != null ? int.tryParse(widgetIdStr) : null;
    }

    debugPrint('打卡小组件配置路由: widgetId=$widgetId');
    return createRoute(CheckinItemSelectorScreen(widgetId: widgetId));
  }

  /// 处理打卡项点击路由
  Route<dynamic> _handleItemClickRoute(String routeName, Object? arguments) {
    String? itemId;
    String? date;

    // 优先从 arguments 中获取（来自小组件点击）
    if (arguments is Map<String, String>) {
      itemId = arguments['itemId'];
      date = arguments['date'];
    } else {
      // 备用：从 URI 中解析
      final uri = Uri.parse(routeName);
      itemId = uri.queryParameters['itemId'];
      date = uri.queryParameters['date'];
    }

    debugPrint('打卡小组件点击: itemId=$itemId, date=$date');

    // 如果有 itemId，打开打卡插件并自动展示打卡记录对话框
    if (itemId != null) {
      return createRoute(CheckinMainView(itemId: itemId, targetDate: date));
    }

    // 没有 itemId，正常打开打卡插件
    return createRoute(const CheckinMainView());
  }
}
