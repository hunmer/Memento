
import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'memento_widgets_platform_interface.dart';

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
  static const Map<String, String> _androidProviders = {
    'TextWidgetProvider': 'com.example.memento_widgets.TextWidgetProvider',
    'ImageWidgetProvider': 'com.example.memento_widgets.ImageWidgetProvider',
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
}

