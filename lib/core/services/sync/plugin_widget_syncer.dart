import 'package:flutter/material.dart';
import '../system_widget_service.dart';

/// 插件小组件同步器基类
///
/// 每个插件的同步器都应该继承此类并实现 sync 方法
abstract class PluginWidgetSyncer {
  /// 同步插件小组件数据
  Future<void> sync();

  /// 更新小组件数据的通用方法
  Future<void> updateWidget({
    required String pluginId,
    required String pluginName,
    required int iconCodePoint,
    required int colorValue,
    required List<WidgetStatItem> stats,
  }) async {
    final widgetData = PluginWidgetData(
      pluginId: pluginId,
      pluginName: pluginName,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      stats: stats,
    );

    await SystemWidgetService.instance.updateWidgetData(pluginId, widgetData);
  }

  /// 检查平台是否支持小组件
  bool isWidgetSupported() {
    return SystemWidgetService.instance.isWidgetSupported();
  }

  /// 安全执行同步，捕获异常
  Future<void> syncSafely(String pluginName, Future<void> Function() syncFn) async {
    try {
      await syncFn();
    } catch (e) {
      debugPrint('Failed to sync $pluginName widget: $e');
    }
  }
}
