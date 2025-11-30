import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:memento_widgets/memento_widgets.dart';

// 重新导出数据模型，供其他文件使用
export 'package:memento_widgets/memento_widgets.dart' show PluginWidgetData, WidgetStatItem;

/// 系统桌面小组件数据同步服务
///
/// 负责将各插件的统计数据同步到 Android 系统桌面小组件
class SystemWidgetService {
  static final SystemWidgetService _instance = SystemWidgetService._internal();
  factory SystemWidgetService() => _instance;
  SystemWidgetService._internal();

  static SystemWidgetService get instance => _instance;

  /// SharedPreferences 的前缀名
  static const String _appGroupId = 'group.github.hunmer.memento';

  /// 初始化 home_widget
  Future<void> initialize() async {
    // 只在 iOS 平台上设置 App Group ID，因为 setAppGroupId 只在 iOS 上有效
    if (UniversalPlatform.isIOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }
  }

  /// 更新插件小组件数据
  ///
  /// [pluginId] 插件ID
  /// [data] 小组件数据
  Future<void> updateWidgetData(String pluginId, PluginWidgetData data) async {
    // 只在支持的平台上运行（Android 和 iOS）
    if (!_isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for $pluginId');
      return;
    }

    try {
      // 改为调用 memento_widgets 的 API
      await MyWidgetManager().updatePluginWidgetData(pluginId, data);
    } catch (e) {
      debugPrint('Failed to update widget data for $pluginId: $e');
    }
  }

  /// 更新指定插件的所有小组件
  Future<void> updateWidget(String pluginId) async {
    // 只在支持的平台上运行（Android 和 iOS）
    if (!_isWidgetSupported()) {
      return;
    }

    try {
      await MyWidgetManager().updatePluginWidget(pluginId);
    } catch (e) {
      debugPrint('Failed to update widget $pluginId: $e');
    }
  }

  /// 更新所有插件的小组件
  Future<void> updateAllWidgets() async {
    // 只在支持的平台上运行（Android 和 iOS）
    if (!_isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping updateAllWidgets');
      return;
    }

    try {
      await MyWidgetManager().updateAllPluginWidgets();
    } catch (e) {
      debugPrint('Failed to update all widgets: $e');
    }
  }

  /// 处理小组件点击事件
  Future<Uri?> getInitialUri() async {
    // 只在支持的平台上运行（Android 和 iOS）
    if (!_isWidgetSupported()) {
      return null;
    }

    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (e) {
      debugPrint('Failed to get initial URI from widget: $e');
      return null;
    }
  }

  /// 监听小组件点击事件
  Stream<Uri?> get widgetClicked {
    // 只在支持的平台上运行（Android 和 iOS）
    if (!_isWidgetSupported()) {
      return Stream.empty();
    }

    try {
      return HomeWidget.widgetClicked;
    } catch (e) {
      debugPrint('Failed to get widget clicked stream: $e');
      return Stream.empty();
    }
  }

  /// 检查当前平台是否支持小组件
  bool isWidgetSupported() {
    return UniversalPlatform.isAndroid || UniversalPlatform.isIOS;
  }

  /// 检查当前平台是否支持小组件（私有方法）
  bool _isWidgetSupported() {
    return isWidgetSupported();
  }
}
