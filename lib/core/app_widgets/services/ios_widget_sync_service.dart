import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/app_widgets/models/ios_widget_config.dart';
import 'package:Memento/core/app_widgets/services/ios_widget_renderer.dart';
import 'package:Memento/core/app_widgets/services/widget_size_mapper.dart';

/// iOS 小组件同步服务
///
/// 负责：
/// - 保存/加载配置到 App Group
/// - 调用渲染器生成图片
/// - 通知 iOS 刷新小组件
class IOSWidgetSyncService {
  // 单例模式
  static IOSWidgetSyncService? _instance;

  factory IOSWidgetSyncService() => _instance ??= IOSWidgetSyncService._();

  IOSWidgetSyncService._();

  /// 同步小组件配置
  ///
  /// [config] 要同步的配置
  /// [context] 可选的 BuildContext 用于渲染
  ///
  /// 流程：
  /// 1. 获取 HomeWidget 定义
  /// 2. 渲染 Widget 为图片
  /// 3. 保存配置
  /// 4. 通知 iOS 刷新
  Future<bool> syncWidget(IOSWidgetConfig config, [BuildContext? context]) async {
    try {
      if (!Platform.isIOS) {
        debugPrint('[IOSWidgetSyncService] 仅支持 iOS 平台');
        return false;
      }

      // 1. 获取 HomeWidget 定义
      final homeWidget = HomeWidgetRegistry().getWidget(config.homeWidgetId);
      if (homeWidget == null) {
        debugPrint('[IOSWidgetSyncService] 未找到 HomeWidget: ${config.homeWidgetId}');
        return false;
      }

      // 2. 检查是否支持该尺寸
      if (!WidgetSizeMapper.isIOSSizeSupported(
        homeWidget.effectiveSupportedSizes,
        config.size,
      )) {
        debugPrint('[IOSWidgetSyncService] HomeWidget 不支持该尺寸: ${config.size.name}');
        // 尝试使用回退尺寸
        final availableSizes = WidgetSizeMapper.getAvailableIOSSizes(
          homeWidget.effectiveSupportedSizes,
        );
        if (availableSizes.isEmpty) {
          return false;
        }
      }

      // 3. 渲染 Widget
      final renderSuccess = await IOSWidgetRenderer.render(
        homeWidget,
        config.size,
        config.config,
        context,
      );

      if (!renderSuccess) {
        debugPrint('[IOSWidgetSyncService] 渲染失败');
        return false;
      }

      // 4. 保存配置
      await IOSWidgetRenderer.saveConfig(config);

      // 5. 通知 iOS 刷新
      await IOSWidgetRenderer.refreshWidget(config.widgetKind);

      debugPrint('[IOSWidgetSyncService] 同步成功: ${config.widgetKind}');
      return true;
    } catch (e, stack) {
      debugPrint('[IOSWidgetSyncService] 同步异常: $e');
      debugPrint('[IOSWidgetSyncService] 堆栈: $stack');
      return false;
    }
  }

  /// 加载指定小组件的配置
  ///
  /// [widgetKind] iOS Widget Kind
  Future<IOSWidgetConfig?> loadConfig(String widgetKind) async {
    return IOSWidgetRenderer.loadConfig(widgetKind);
  }

  /// 加载所有已保存的配置
  Future<Map<String, IOSWidgetConfig>> loadAllConfigs() async {
    return IOSWidgetRenderer.loadAllConfigs();
  }

  /// 创建新的小组件配置并同步
  ///
  /// [homeWidgetId] HomeWidget ID
  /// [iosSize] iOS 小组件尺寸
  /// [config] 传递给 builder 的配置
  /// [context] 可选的 BuildContext 用于渲染
  Future<IOSWidgetConfig?> createConfig({
    required String homeWidgetId,
    required IOSWidgetSize iosSize,
    Map<String, dynamic>? config,
    BuildContext? context,
  }) async {
    try {
      // 获取 HomeWidget 定义
      final homeWidget = HomeWidgetRegistry().getWidget(homeWidgetId);
      if (homeWidget == null) {
        debugPrint('[IOSWidgetSyncService] 未找到 HomeWidget: $homeWidgetId');
        return null;
      }

      // 创建配置
      final widgetConfig = IOSWidgetConfig(
        widgetKind: 'memento_widget_${iosSize.name}',
        homeWidgetId: homeWidgetId,
        pluginId: homeWidget.pluginId,
        size: iosSize,
        config: config ?? {},
        lastUpdated: DateTime.now(),
      );

      // 同步配置
      final success = await syncWidget(widgetConfig, context);

      return success ? widgetConfig : null;
    } catch (e) {
      debugPrint('[IOSWidgetSyncService] 创建配置异常: $e');
      return null;
    }
  }

  /// 删除小组件配置
  ///
  /// [widgetKind] iOS Widget Kind
  Future<bool> deleteConfig(String widgetKind) async {
    try {
      if (!Platform.isIOS) {
        return false;
      }

      // 解析 iOS 尺寸
      final sizeName = widgetKind.replaceFirst('memento_widget_', '');
      final iosSize = IOSWidgetSize.fromName(sizeName);

      // 删除图片
      await IOSWidgetRenderer.deleteImage(iosSize);

      debugPrint('[IOSWidgetSyncService] 删除配置: $widgetKind');
      return true;
    } catch (e) {
      debugPrint('[IOSWidgetSyncService] 删除配置失败: $e');
      return false;
    }
  }

  /// 刷新所有小组件
  ///
  /// 通常在应用启动或数据更新后调用
  Future<void> refreshAllWidgets() async {
    await IOSWidgetRenderer.refreshAllWidgets();
  }

  /// 获取可用的 iOS 尺寸列表
  ///
  /// [homeWidgetId] HomeWidget ID
  List<IOSWidgetSize> getAvailableSizes(String homeWidgetId) {
    final homeWidget = HomeWidgetRegistry().getWidget(homeWidgetId);
    if (homeWidget == null) {
      return [];
    }

    return WidgetSizeMapper.getAvailableIOSSizes(
      homeWidget.effectiveSupportedSizes,
    );
  }

  /// 检查 HomeWidget 是否支持指定的 iOS 尺寸
  ///
  /// [homeWidgetId] HomeWidget ID
  /// [iosSize] iOS 小组件尺寸
  bool isSizeSupported(String homeWidgetId, IOSWidgetSize iosSize) {
    final homeWidget = HomeWidgetRegistry().getWidget(homeWidgetId);
    if (homeWidget == null) {
      return false;
    }

    return WidgetSizeMapper.isIOSSizeSupported(
      homeWidget.effectiveSupportedSizes,
      iosSize,
    );
  }
}
