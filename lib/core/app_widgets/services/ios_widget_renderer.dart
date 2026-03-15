import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart' as home_widget_pkg;
import 'package:memento_widgets/memento_widgets.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/core/app_widgets/models/ios_widget_config.dart';
import 'package:Memento/core/app_widgets/services/widget_size_mapper.dart';

/// iOS 小组件渲染器
///
/// 负责将 Flutter Widget 渲染为 PNG 图片，供 iOS Widget Extension 显示
class IOSWidgetRenderer {
  // 私有构造函数
  IOSWidgetRenderer._();

  /// App Group ID (iOS)
  static const String _appGroupId = 'group.github.hunmer.memento';

  /// 图片存储键前缀
  static const String _imageKeyPrefix = 'ios_widget_image_';

  /// 配置存储键前缀
  static const String _configKeyPrefix = 'ios_widget_config_';

  /// 渲染 Flutter Widget 为图片并保存到 App Group
  ///
  /// [homeWidgetDef] 要渲染的 HomeWidget 定义
  /// [iosSize] iOS 小组件尺寸
  /// [config] 传递给 builder 的配置
  /// [context] 可选的 BuildContext
  ///
  /// 返回是否渲染成功
  static Future<bool> render(
    HomeWidget homeWidgetDef,
    IOSWidgetSize iosSize,
    Map<String, dynamic> config, [
    BuildContext? context,
  ]) async {
    try {
      // 只在 iOS 平台上执行
      if (!Platform.isIOS) {
        debugPrint('[IOSWidgetRenderer] 仅支持 iOS 平台');
        return false;
      }

      // 初始化 App Group
      await home_widget_pkg.HomeWidget.setAppGroupId(_appGroupId);

      // 获取渲染尺寸（逻辑尺寸）
      final logicalSize = WidgetSizeMapper.getLogicalSize(iosSize);
      final pixelRatio = 3.0;

      // 获取对应的 HomeWidgetSize
      final homeWidgetSize = WidgetSizeMapper.iosToHome(iosSize);

      // 注入尺寸信息到 config
      final effectiveConfig = <String, dynamic>{
        ...config,
        'widgetSize': homeWidgetSize,
      };

      // 构建 Widget
      Widget widget;
      if (context != null) {
        widget = homeWidgetDef.build(context, effectiveConfig, homeWidgetSize);
      } else {
        // 使用默认的 Widget
        widget = _buildDefaultWidget(homeWidgetDef, homeWidgetSize, effectiveConfig);
      }

      // 包装 Widget 以确保有完整的 Material 和 MediaQuery
      final wrappedWidget = _wrapWidget(widget, logicalSize);

      // 使用 MyWidgetManager.renderFlutterWidget() 渲染
      final widgetManager = MyWidgetManager();
      final success = await widgetManager.renderFlutterWidget(
        wrappedWidget,
        key: '$_imageKeyPrefix${iosSize.name}',
        logicalSize: logicalSize,
        pixelRatio: pixelRatio,
      );

      if (success) {
        debugPrint('[IOSWidgetRenderer] 渲染成功: ${iosSize.name}');
      } else {
        debugPrint('[IOSWidgetRenderer] 渲染失败: ${iosSize.name}');
      }

      return success;
    } catch (e, stack) {
      debugPrint('[IOSWidgetRenderer] 渲染异常: $e');
      debugPrint('[IOSWidgetRenderer] 堆栈: $stack');
      return false;
    }
  }

  /// 包装 Widget 以确保有完整的 Material 和 MediaQuery
  static Widget _wrapWidget(Widget widget, Size logicalSize) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: logicalSize),
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建默认 Widget（当没有 Context 时）
  static Widget _buildDefaultWidget(
    HomeWidget homeWidgetDef,
    HomeWidgetSize size,
    Map<String, dynamic> config,
  ) {
    // 返回一个简单的占位 Widget
    return Container(
      decoration: BoxDecoration(
        color: homeWidgetDef.color ?? Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              homeWidgetDef.icon,
              size: size.getIconSize() * 2,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                homeWidgetDef.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.getTitleFontSize(),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存 iOS 小组件配置到 App Group
  ///
  /// [config] 要保存的配置
  static Future<bool> saveConfig(IOSWidgetConfig config) async {
    try {
      if (!Platform.isIOS) {
        return false;
      }

      await home_widget_pkg.HomeWidget.setAppGroupId(_appGroupId);

      final configKey = '$_configKeyPrefix${config.widgetKind}';
      final configJson = jsonEncode(config.toJson());

      final result = await home_widget_pkg.HomeWidget.saveWidgetData<String>(configKey, configJson);

      debugPrint('[IOSWidgetRenderer] 保存配置: $configKey');
      return result != null;
    } catch (e) {
      debugPrint('[IOSWidgetRenderer] 保存配置失败: $e');
      return false;
    }
  }

  /// 从 App Group 加载 iOS 小组件配置
  ///
  /// [widgetKind] iOS Widget Kind
  static Future<IOSWidgetConfig?> loadConfig(String widgetKind) async {
    try {
      if (!Platform.isIOS) {
        return null;
      }

      await home_widget_pkg.HomeWidget.setAppGroupId(_appGroupId);

      final configKey = '$_configKeyPrefix$widgetKind';
      final configJson = await home_widget_pkg.HomeWidget.getWidgetData<String>(configKey);

      if (configJson != null && configJson.isNotEmpty) {
        final json = jsonDecode(configJson) as Map<String, dynamic>;
        return IOSWidgetConfig.fromJson(json);
      }

      return null;
    } catch (e) {
      debugPrint('[IOSWidgetRenderer] 加载配置失败: $e');
      return null;
    }
  }

  /// 加载所有已保存的配置
  static Future<Map<String, IOSWidgetConfig>> loadAllConfigs() async {
    final configs = <String, IOSWidgetConfig>{};

    try {
      if (!Platform.isIOS) {
        return configs;
      }

      // 尝试加载三种尺寸的配置
      for (final size in IOSWidgetSize.values) {
        final widgetKind = 'memento_widget_${size.name}';
        final config = await loadConfig(widgetKind);
        if (config != null && config.homeWidgetId.isNotEmpty) {
          configs[widgetKind] = config;
        }
      }

      return configs;
    } catch (e) {
      debugPrint('[IOSWidgetRenderer] 加载所有配置失败: $e');
      return configs;
    }
  }

  /// 通知 iOS 刷新小组件
  ///
  /// [widgetKind] 要刷新的 iOS Widget Kind
  static Future<bool> refreshWidget(String widgetKind) async {
    try {
      if (!Platform.isIOS) {
        return false;
      }

      await home_widget_pkg.HomeWidget.updateWidget(
        iOSName: widgetKind,
        name: widgetKind,
      );

      debugPrint('[IOSWidgetRenderer] 刷新小组件: $widgetKind');
      return true;
    } catch (e) {
      debugPrint('[IOSWidgetRenderer] 刷新小组件失败: $e');
      return false;
    }
  }

  /// 刷新所有已配置的小组件
  static Future<void> refreshAllWidgets() async {
    final configs = await loadAllConfigs();

    for (final config in configs.values) {
      await refreshWidget(config.widgetKind);
    }
  }

  /// 删除小组件图片
  ///
  /// [iosSize] 要删除的 iOS 尺寸
  static Future<bool> deleteImage(IOSWidgetSize iosSize) async {
    try {
      if (!Platform.isIOS) {
        return false;
      }

      await home_widget_pkg.HomeWidget.setAppGroupId(_appGroupId);

      final imageKey = '$_imageKeyPrefix${iosSize.name}';
      await home_widget_pkg.HomeWidget.saveWidgetData<String>(imageKey, '');

      debugPrint('[IOSWidgetRenderer] 删除图片: $imageKey');
      return true;
    } catch (e) {
      debugPrint('[IOSWidgetRenderer] 删除图片失败: $e');
      return false;
    }
  }
}
