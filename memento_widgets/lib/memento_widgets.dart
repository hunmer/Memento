
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'memento_widgets_platform_interface.dart';

// 导出数据模型
export 'models/plugin_widget_data.dart';
export 'models/widget_stat_item.dart';

// 导入数据模型
import 'models/plugin_widget_data.dart';

class MementoWidgets {
  Future<String?> getPlatformVersion() {
    return MementoWidgetsPlatform.instance.getPlatformVersion();
  }
}

/// 小组件管理器单例类
/// 包装 home_widget 的方法，提供简化的 API
class MyWidgetManager {
  // 单例模式
  static MyWidgetManager? _instance;

  /// Android Provider 完整包名映射
  /// 格式: '简单类名' -> '完整包名'
  static const Map<String, String> _androidProviders = {
    // 示例小组件
    'TextWidgetProvider': 'com.example.memento_widgets.TextWidgetProvider',
    'ImageWidgetProvider': 'com.example.memento_widgets.ImageWidgetProvider',

    // 插件小组件 - 1x1 尺寸
    'TodoWidgetProvider': 'github.hunmer.memento.widgets.providers.TodoWidgetProvider',
    'TimerWidgetProvider': 'github.hunmer.memento.widgets.providers.TimerWidgetProvider',
    'BillWidgetProvider': 'github.hunmer.memento.widgets.providers.BillWidgetProvider',
    'CalendarWidgetProvider': 'github.hunmer.memento.widgets.providers.CalendarWidgetProvider',
    'ActivityWidgetProvider': 'github.hunmer.memento.widgets.providers.ActivityWidgetProvider',
    'TrackerWidgetProvider': 'github.hunmer.memento.widgets.providers.TrackerWidgetProvider',
    'HabitsWidgetProvider': 'github.hunmer.memento.widgets.providers.HabitsWidgetProvider',
    'DiaryWidgetProvider': 'github.hunmer.memento.widgets.providers.DiaryWidgetProvider',
    'CheckinWidgetProvider': 'github.hunmer.memento.widgets.providers.CheckinWidgetProvider',
    'NodesWidgetProvider': 'github.hunmer.memento.widgets.providers.NodesWidgetProvider',
    'DatabaseWidgetProvider': 'github.hunmer.memento.widgets.providers.DatabaseWidgetProvider',
    'ContactWidgetProvider': 'github.hunmer.memento.widgets.providers.ContactWidgetProvider',
    'DayWidgetProvider': 'github.hunmer.memento.widgets.providers.DayWidgetProvider',
    'GoodsWidgetProvider': 'github.hunmer.memento.widgets.providers.GoodsWidgetProvider',
    'NotesWidgetProvider': 'github.hunmer.memento.widgets.providers.NotesWidgetProvider',
    'StoreWidgetProvider': 'github.hunmer.memento.widgets.providers.StoreWidgetProvider',
    'OpenaiWidgetProvider': 'github.hunmer.memento.widgets.providers.OpenaiWidgetProvider',
    'AgentChatWidgetProvider': 'github.hunmer.memento.widgets.providers.AgentChatWidgetProvider',
    'CalendarAlbumWidgetProvider': 'github.hunmer.memento.widgets.providers.CalendarAlbumWidgetProvider',
    'ChatWidgetProvider': 'github.hunmer.memento.widgets.providers.ChatWidgetProvider',

    // 插件小组件 - 2x2 尺寸
    'TodoWidget2x1Provider': 'github.hunmer.memento.widgets.providers.TodoWidget2x1Provider',
    'TimerWidget2x1Provider': 'github.hunmer.memento.widgets.providers.TimerWidget2x1Provider',
    'BillWidget2x1Provider': 'github.hunmer.memento.widgets.providers.BillWidget2x1Provider',
    'CalendarWidget2x1Provider': 'github.hunmer.memento.widgets.providers.CalendarWidget2x1Provider',
    'ActivityWidget2x1Provider': 'github.hunmer.memento.widgets.providers.ActivityWidget2x1Provider',
    'TrackerWidget2x1Provider': 'github.hunmer.memento.widgets.providers.TrackerWidget2x1Provider',
    'HabitsWidget2x1Provider': 'github.hunmer.memento.widgets.providers.HabitsWidget2x1Provider',
    'DiaryWidget2x1Provider': 'github.hunmer.memento.widgets.providers.DiaryWidget2x1Provider',
    'CheckinWidget2x1Provider': 'github.hunmer.memento.widgets.providers.CheckinWidget2x1Provider',
    'NodesWidget2x1Provider': 'github.hunmer.memento.widgets.providers.NodesWidget2x1Provider',
    'DatabaseWidget2x1Provider': 'github.hunmer.memento.widgets.providers.DatabaseWidget2x1Provider',
    'ContactWidget2x1Provider': 'github.hunmer.memento.widgets.providers.ContactWidget2x1Provider',
    'DayWidget2x1Provider': 'github.hunmer.memento.widgets.providers.DayWidget2x1Provider',
    'GoodsWidget2x1Provider': 'github.hunmer.memento.widgets.providers.GoodsWidget2x1Provider',
    'NotesWidget2x1Provider': 'github.hunmer.memento.widgets.providers.NotesWidget2x1Provider',
    'StoreWidget2x1Provider': 'github.hunmer.memento.widgets.providers.StoreWidget2x1Provider',
    'OpenaiWidget2x1Provider': 'github.hunmer.memento.widgets.providers.OpenaiWidget2x1Provider',
    'AgentChatWidget2x1Provider': 'github.hunmer.memento.widgets.providers.AgentChatWidget2x1Provider',
    'CalendarAlbumWidget2x1Provider': 'github.hunmer.memento.widgets.providers.CalendarAlbumWidget2x1Provider',
    'ChatWidget2x1Provider': 'github.hunmer.memento.widgets.providers.ChatWidget2x1Provider',
    'CheckinItemWidgetProvider': 'github.hunmer.memento.widgets.providers.CheckinItemWidgetProvider',
    'CheckinMonthWidgetProvider': 'github.hunmer.memento.widgets.providers.CheckinMonthWidgetProvider',
    'TodoListWidgetProvider': 'github.hunmer.memento.widgets.providers.TodoListWidgetProvider',

    // 快速小组件
    'ChatQuickWidgetProvider': 'github.hunmer.memento.widgets.quick.ChatQuickWidgetProvider',
    'AgentVoiceWidgetProvider': 'github.hunmer.memento.widgets.quick.AgentVoiceWidgetProvider',
  };

  /// 获取单例实例
  factory MyWidgetManager() => _instance ??= MyWidgetManager._internal();

  MyWidgetManager._internal();

  /// 初始化 (对于 iOS App Group，Android 可选)
  Future<void> init(String? appGroupId) async {
    if (appGroupId != null) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
    // 可添加其他初始化，如注册背景任务
  }

  /// 保存字符串数据到小组件共享存储
  Future<bool> saveString(String key, String value) async {
    try {
      if (value.isEmpty) return false;
      final result = await HomeWidget.saveWidgetData<String>(key, value);
      return result == true;
    } catch (e) {
      debugPrint('保存字符串数据失败: $e');
      return false;
    }
  }

  /// 保存整数数据到小组件共享存储
  Future<bool> saveInt(String key, int value) async {
    try {
      final result = await HomeWidget.saveWidgetData<int>(key, value);
      return result == true;
    } catch (e) {
      debugPrint('保存整数数据失败: $e');
      return false;
    }
  }

  /// 保存布尔数据到小组件共享存储
  Future<bool> saveBool(String key, bool value) async {
    try {
      final result = await HomeWidget.saveWidgetData<bool>(key, value);
      return result == true;
    } catch (e) {
      debugPrint('保存布尔数据失败: $e');
      return false;
    }
  }

  /// 保存双精度数据到小组件共享存储
  Future<bool> saveDouble(String key, double value) async {
    try {
      final result = await HomeWidget.saveWidgetData<double>(key, value);
      return result == true;
    } catch (e) {
      debugPrint('保存双精度数据失败: $e');
      return false;
    }
  }

  /// 从共享存储读取数据
  Future<T?> getData<T>(String key) async {
    return await HomeWidget.getWidgetData<T>(key);
  }

  /// 更新指定名称的小组件
  /// [widgetName] 可以是以下值之一：
  /// - 'TextWidgetProvider' 或 '文本小组件' (文本小组件)
  /// - 'ImageWidgetProvider' 或 '图像小组件' (图像小组件)
  /// 如果不指定，将同时更新两个小组件
  Future<bool> updateWidget({String? widgetName}) async {
    try {
      final targets = widgetName == null
          ? ['TextWidgetProvider', 'ImageWidgetProvider']
          : [widgetName];
      final results = await Future.wait(targets.map((name) {
        final qualifiedAndroidName = _androidProviders[name];
        return HomeWidget.updateWidget(
          name: name,
          iOSName: name,
          androidName: qualifiedAndroidName == null ? name : null,
          qualifiedAndroidName: qualifiedAndroidName,
        );
      }));
      return results.every((result) => result == true);
    } catch (e) {
      debugPrint('???????: $e');
      return false;
    }
  }

  /// 渲染 Flutter UI 为图像（用于 ImageWidget）
  /// [flutterWidget] 要渲染的 Flutter Widget
  /// [key] 保存图像的键名
  /// [logicalSize] 渲染的逻辑大小
  /// [pixelRatio] 像素比率，默认为 1.0
  Future<bool> renderFlutterWidget(
    Widget flutterWidget, {
    required String key,
    required Size logicalSize,
    double pixelRatio = 1.0,
  }) async {
    try {
      final result = await HomeWidget.renderFlutterWidget(
        flutterWidget,
        key: key,
        logicalSize: logicalSize,
        pixelRatio: pixelRatio,
      );
      return result == true;
    } catch (e) {
      debugPrint('渲染 Flutter Widget 失败: $e');
      return false;
    }
  }

  /// 注册交互回调（用于处理小组件点击等事件）
  void registerInteractivityCallback(Function(Uri?) callback) {
    HomeWidget.registerInteractivityCallback(callback);
  }

  /// 获取初始 Uri（用于应用启动时）
  Future<Uri?> getInitialUri() async {
    return await HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  // ========== 插件小组件相关方法 ==========

  /// 更新插件小组件数据
  Future<void> updatePluginWidgetData(
    String pluginId,
    PluginWidgetData data,
  ) async {
    try {
      final jsonData = jsonEncode(data.toJson());
      await saveString('${pluginId}_widget_data', jsonData);
      await updatePluginWidget(pluginId);
    } catch (e) {
      debugPrint('Failed to update plugin widget data for $pluginId: $e');
    }
  }

  /// 更新指定插件的小组件（同时更新1x1和2x2尺寸）
  Future<void> updatePluginWidget(String pluginId) async {
    final providerNames = _getProviderNames(pluginId);
    for (final providerName in providerNames) {
      try {
        await updateWidget(widgetName: providerName);
      } catch (e) {
        debugPrint('Failed to update widget $providerName: $e');
      }
    }
  }

  /// 更新所有插件小组件
  Future<void> updateAllPluginWidgets() async {
    final providers = _getAllProviderNames();
    for (final provider in providers) {
      try {
        await updateWidget(widgetName: provider);
      } catch (e) {
        debugPrint('Failed to update widget $provider: $e');
      }
    }
  }

  /// 插件ID 到 Provider 名称列表的映射（包含1x1和2x2尺寸）
  List<String> _getProviderNames(String pluginId) {
    if (pluginId == 'checkin_item') {
      return ['CheckinItemWidgetProvider'];
    }
    if (pluginId == 'checkin_month') {
      return ['CheckinMonthWidgetProvider'];
    }
    if (pluginId == 'todo_list') {
      return ['TodoListWidgetProvider'];
    }
    const provider1x1Map = {
      'todo': 'TodoWidgetProvider',
      'timer': 'TimerWidgetProvider',
      'bill': 'BillWidgetProvider',
      'calendar': 'CalendarWidgetProvider',
      'activity': 'ActivityWidgetProvider',
      'tracker': 'TrackerWidgetProvider',
      'habits': 'HabitsWidgetProvider',
      'diary': 'DiaryWidgetProvider',
      'checkin': 'CheckinWidgetProvider',
      'nodes': 'NodesWidgetProvider',
      'database': 'DatabaseWidgetProvider',
      'contact': 'ContactWidgetProvider',
      'day': 'DayWidgetProvider',
      'goods': 'GoodsWidgetProvider',
      'notes': 'NotesWidgetProvider',
      'store': 'StoreWidgetProvider',
      'openai': 'OpenaiWidgetProvider',
      'agent_chat': 'AgentChatWidgetProvider',
      'calendar_album': 'CalendarAlbumWidgetProvider',
      'chat': 'ChatWidgetProvider',
    };

    const provider2x1Map = {
      'todo': 'TodoWidget2x1Provider',
      'timer': 'TimerWidget2x1Provider',
      'bill': 'BillWidget2x1Provider',
      'calendar': 'CalendarWidget2x1Provider',
      'activity': 'ActivityWidget2x1Provider',
      'tracker': 'TrackerWidget2x1Provider',
      'habits': 'HabitsWidget2x1Provider',
      'diary': 'DiaryWidget2x1Provider',
      'checkin': 'CheckinWidget2x1Provider',
      'nodes': 'NodesWidget2x1Provider',
      'database': 'DatabaseWidget2x1Provider',
      'contact': 'ContactWidget2x1Provider',
      'day': 'DayWidget2x1Provider',
      'goods': 'GoodsWidget2x1Provider',
      'notes': 'NotesWidget2x1Provider',
      'store': 'StoreWidget2x1Provider',
      'openai': 'OpenaiWidget2x1Provider',
      'agent_chat': 'AgentChatWidget2x1Provider',
      'calendar_album': 'CalendarAlbumWidget2x1Provider',
      'chat': 'ChatWidget2x1Provider',
    };

    final providers = <String>[];
    final provider1x1 = provider1x1Map[pluginId];
    final provider2x1 = provider2x1Map[pluginId];

    if (provider1x1 != null) providers.add(provider1x1);
    if (provider2x1 != null) providers.add(provider2x1);

    return providers;
  }

  /// 获取所有 Provider 名称（包含1x1和2x2尺寸）
  List<String> _getAllProviderNames() {
    return [
      // 1x1 尺寸小组件
      'TodoWidgetProvider',
      'TimerWidgetProvider',
      'BillWidgetProvider',
      'CalendarWidgetProvider',
      'ActivityWidgetProvider',
      'TrackerWidgetProvider',
      'HabitsWidgetProvider',
      'DiaryWidgetProvider',
      'CheckinWidgetProvider',
      'NodesWidgetProvider',
      'DatabaseWidgetProvider',
      'ContactWidgetProvider',
      'DayWidgetProvider',
      'GoodsWidgetProvider',
      'NotesWidgetProvider',
      'StoreWidgetProvider',
      'OpenaiWidgetProvider',
      'AgentChatWidgetProvider',
      'CalendarAlbumWidgetProvider',
      'ChatWidgetProvider',
      // 2x2 尺寸小组件
      'TodoWidget2x1Provider',
      'TimerWidget2x1Provider',
      'BillWidget2x1Provider',
      'CalendarWidget2x1Provider',
      'ActivityWidget2x1Provider',
      'TrackerWidget2x1Provider',
      'HabitsWidget2x1Provider',
      'DiaryWidget2x1Provider',
      'CheckinWidget2x1Provider',
      'NodesWidget2x1Provider',
      'DatabaseWidget2x1Provider',
      'ContactWidget2x1Provider',
      'DayWidget2x1Provider',
      'GoodsWidget2x1Provider',
      'NotesWidget2x1Provider',
      'StoreWidget2x1Provider',
      'OpenaiWidget2x1Provider',
      'AgentChatWidget2x1Provider',
      'CalendarAlbumWidget2x1Provider',
      'ChatWidget2x1Provider',
      // 自定义小组件
      'CheckinItemWidgetProvider',
      'CheckinMonthWidgetProvider',
      'TodoListWidgetProvider',
    ];
  }
}

