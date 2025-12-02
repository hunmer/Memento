import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/bill_shortcut.dart';

/// 快捷记账小组件数据同步服务
///
/// 负责管理快捷记账小组件的配置数据,包括:
/// - 保存小组件配置到 SharedPreferences
/// - 加载小组件配置
/// - 删除小组件配置
/// - 触发小组件更新
class BillShortcutsWidgetService {
  static final BillShortcutsWidgetService _instance = BillShortcutsWidgetService._internal();
  factory BillShortcutsWidgetService() => _instance;
  BillShortcutsWidgetService._internal();

  static BillShortcutsWidgetService get instance => _instance;

  /// 小组件配置的键名前缀
  static const String _configKeyPrefix = 'bill_shortcuts_widget_';

  /// 小组件颜色配置的键名前缀
  static const String _colorKeyPrefix = 'bill_shortcuts_widget_color_';

  /// 保存小组件配置
  ///
  /// [config] 小组件配置对象
  /// 返回是否保存成功
  Future<bool> saveWidgetConfig(BillShortcutsWidgetConfig config) async {
    try {
      final configKey = '$_configKeyPrefix${config.widgetId}';
      final configJson = jsonEncode(config.toJson());

      // 使用 HomeWidget 保存配置数据
      final success = await HomeWidget.saveWidgetData<String>(
        configKey,
        configJson,
      );

      if (success == true) {
        debugPrint('BillShortcutsWidgetService: 配置已保存 (widgetId: ${config.widgetId})');
        // 保存成功后触发小组件更新
        await updateWidget(config.widgetId);
      } else {
        debugPrint('BillShortcutsWidgetService: 配置保存失败 (widgetId: ${config.widgetId})');
      }

      return success ?? false;
    } catch (e) {
      debugPrint('BillShortcutsWidgetService: 保存配置时出错: $e');
      return false;
    }
  }

  /// 加载小组件配置
  ///
  /// [widgetId] 小组件ID
  /// 返回配置对象,如果不存在则返回 null
  Future<BillShortcutsWidgetConfig?> loadWidgetConfig(int widgetId) async {
    try {
      final configKey = '$_configKeyPrefix$widgetId';
      final configJson = await HomeWidget.getWidgetData<String>(configKey);

      if (configJson == null || configJson.isEmpty) {
        debugPrint('BillShortcutsWidgetService: 未找到配置 (widgetId: $widgetId)');
        return null;
      }

      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      final config = BillShortcutsWidgetConfig.fromJson(configMap);

      debugPrint('BillShortcutsWidgetService: 配置已加载 (widgetId: $widgetId, shortcuts: ${config.shortcuts.length})');
      return config;
    } catch (e) {
      debugPrint('BillShortcutsWidgetService: 加载配置时出错: $e');
      return null;
    }
  }

  /// 删除小组件配置
  ///
  /// [widgetId] 小组件ID
  /// 返回是否删除成功
  Future<bool> deleteWidgetConfig(int widgetId) async {
    try {
      final configKey = '$_configKeyPrefix$widgetId';
      final colorKey = '$_colorKeyPrefix$widgetId';

      // 删除配置数据
      await HomeWidget.saveWidgetData<String>(configKey, null);

      // 删除颜色配置
      await HomeWidget.saveWidgetData<String>(colorKey, null);

      debugPrint('BillShortcutsWidgetService: 配置已删除 (widgetId: $widgetId)');
      return true;
    } catch (e) {
      debugPrint('BillShortcutsWidgetService: 删除配置时出错: $e');
      return false;
    }
  }

  /// 保存小组件颜色配置
  ///
  /// [widgetId] 小组件ID
  /// [backgroundColor] 背景颜色
  /// [textColor] 文本颜色
  /// [iconColor] 图标颜色
  ///
  /// 注意: 颜色值必须存储为 String 类型,因为 HomeWidget 的限制
  /// Android 端读取时使用: colorStr?.toLongOrNull()?.toInt()
  Future<bool> saveWidgetColors({
    required int widgetId,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) async {
    try {
      final colorKey = '$_colorKeyPrefix$widgetId';
      final colorConfig = {
        'backgroundColor': backgroundColor.value.toString(),
        'textColor': textColor.value.toString(),
        'iconColor': iconColor.value.toString(),
      };
      final colorJson = jsonEncode(colorConfig);

      final success = await HomeWidget.saveWidgetData<String>(
        colorKey,
        colorJson,
      );

      if (success == true) {
        debugPrint('BillShortcutsWidgetService: 颜色配置已保存 (widgetId: $widgetId)');
        // 保存成功后触发小组件更新
        await updateWidget(widgetId);
      } else {
        debugPrint('BillShortcutsWidgetService: 颜色配置保存失败 (widgetId: $widgetId)');
      }

      return success ?? false;
    } catch (e) {
      debugPrint('BillShortcutsWidgetService: 保存颜色配置时出错: $e');
      return false;
    }
  }

  /// 加载小组件颜色配置
  ///
  /// [widgetId] 小组件ID
  /// 返回颜色配置 Map,如果不存在则返回 null
  Future<Map<String, Color>?> loadWidgetColors(int widgetId) async {
    try {
      final colorKey = '$_colorKeyPrefix$widgetId';
      final colorJson = await HomeWidget.getWidgetData<String>(colorKey);

      if (colorJson == null || colorJson.isEmpty) {
        debugPrint('BillShortcutsWidgetService: 未找到颜色配置 (widgetId: $widgetId)');
        return null;
      }

      final colorMap = jsonDecode(colorJson) as Map<String, dynamic>;

      return {
        'backgroundColor': Color(int.parse(colorMap['backgroundColor'] as String)),
        'textColor': Color(int.parse(colorMap['textColor'] as String)),
        'iconColor': Color(int.parse(colorMap['iconColor'] as String)),
      };
    } catch (e) {
      debugPrint('BillShortcutsWidgetService: 加载颜色配置时出错: $e');
      return null;
    }
  }

  /// 触发小组件更新
  ///
  /// [widgetId] 小组件ID
  Future<void> updateWidget(int widgetId) async {
    try {
      // 使用 HomeWidget 触发 Android 端的小组件更新
      await HomeWidget.updateWidget(
        name: 'BillShortcutsWidgetProvider',
        androidName: 'BillShortcutsWidgetProvider',
      );
      debugPrint('BillShortcutsWidgetService: 小组件更新已触发 (widgetId: $widgetId)');
    } catch (e) {
      debugPrint('BillShortcutsWidgetService: 触发小组件更新时出错: $e');
    }
  }

  /// 检查小组件配置是否存在
  ///
  /// [widgetId] 小组件ID
  /// 返回配置是否存在
  Future<bool> hasWidgetConfig(int widgetId) async {
    try {
      final configKey = '$_configKeyPrefix$widgetId';
      final configJson = await HomeWidget.getWidgetData<String>(configKey);
      return configJson != null && configJson.isNotEmpty;
    } catch (e) {
      debugPrint('BillShortcutsWidgetService: 检查配置是否存在时出错: $e');
      return false;
    }
  }
}

/// 使用示例:
///
/// ```dart
/// // 保存小组件配置
/// final config = BillShortcutsWidgetConfig(
///   widgetId: 123,
///   shortcuts: [...],
/// );
/// await BillShortcutsWidgetService.instance.saveWidgetConfig(config);
///
/// // 保存颜色配置
/// await BillShortcutsWidgetService.instance.saveWidgetColors(
///   widgetId: 123,
///   backgroundColor: Colors.white,
///   textColor: Colors.black,
///   iconColor: Colors.blue,
/// );
///
/// // 加载配置
/// final loadedConfig = await BillShortcutsWidgetService.instance.loadWidgetConfig(123);
///
/// // 删除配置
/// await BillShortcutsWidgetService.instance.deleteWidgetConfig(123);
/// ```
