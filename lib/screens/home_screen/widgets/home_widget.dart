import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';

/// 小组件构建器函数类型
typedef HomeWidgetBuilder = Widget Function(BuildContext context, Map<String, dynamic> config);

/// 可用统计项提供者函数类型
typedef AvailableStatsProvider = List<StatItemData> Function(BuildContext context);

/// 数据渲染器：将选择器结果渲染为Widget
typedef SelectorDataRenderer = Widget Function(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
);

/// 导航处理器：处理点击后的跳转逻辑
typedef SelectorNavigationHandler = void Function(
  BuildContext context,
  SelectorResult result,
);

/// 数据选择器结果处理器（可选）
///
/// 将选择器返回的数据数组转换为小组件需要的格式
/// 返回一个 Map，包含小组件需要的所有数据字段
///
/// 参数：
/// - dataArray: 选择器返回的数据数组，每项对应一个选择步骤的结果
///
/// 返回：
/// - `Map<String, dynamic>`：小组件需要的数据，字段名自定义
///
/// 示例：
/// ```dart
/// dataSelector: (dataArray) {
///   final accountData = dataArray[0] as Map<String, dynamic>;
///   final periodData = dataArray[1] as Map<String, dynamic>;
///   return {
///     'accountId': accountData['id'],
///     'accountTitle': accountData['title'],
///     'periodLabel': periodData['label'],
///     'startDate': periodData['start'],
///     'endDate': periodData['end'],
///   };
/// }
/// ```
typedef SelectorDataSelector = Map<String, dynamic> Function(List<dynamic> dataArray);

/// 主页小组件定义
///
/// 每个插件可以注册多个小组件，这些小组件会在"添加组件"对话框中显示
/// 用户选择后会创建 HomeWidgetItem 实例放置在主页上
class HomeWidget {
  /// 唯一标识符（格式建议：pluginId_widgetName）
  final String id;

  /// 所属插件ID
  final String pluginId;

  /// 显示名称
  final String name;

  /// 描述（可选，在选择对话框中显示）
  final String? description;

  /// 图标
  final IconData icon;

  /// 主题色（可选，默认使用插件颜色）
  final Color? color;

  /// 默认尺寸
  final HomeWidgetSize defaultSize;

  /// 支持的尺寸列表
  final List<HomeWidgetSize> supportedSizes;

  /// 分类（用于对话框分组显示）
  final String category;

  /// 构建器函数
  ///
  /// 参数：
  /// - context: BuildContext
  /// - config: 小组件实例的配置数据（来自 HomeWidgetItem.config）
  final HomeWidgetBuilder builder;

  /// 可用统计项提供者（可选）
  ///
  /// 用于小组件设置对话框，提供可选择的统计项列表
  final AvailableStatsProvider? availableStatsProvider;

  // ===== 数据选择器相关字段（可选） =====

  /// 关联的数据选择器ID（可选）
  ///
  /// 如果提供，则该小组件支持通过数据选择器选择数据
  /// 格式：pluginId.selectorName（如 'webview.card'）
  final String? selectorId;

  /// 数据渲染器（可选）
  ///
  /// 将选择器返回的 SelectorResult 渲染为 Widget
  /// 仅在 selectorId 不为 null 时有效
  final SelectorDataRenderer? dataRenderer;

  /// 导航处理器（可选）
  ///
  /// 处理用户点击已配置小组件时的跳转逻辑
  /// 仅在 selectorId 不为 null 时有效
  final SelectorNavigationHandler? navigationHandler;

  /// 数据选择器结果处理器（可选）
  ///
  /// 将选择器返回的数据数组转换为小组件需要的格式
  /// 如果未提供，默认将 dataArray 合并为一个 Map
  final SelectorDataSelector? dataSelector;

  const HomeWidget({
    required this.id,
    required this.pluginId,
    required this.name,
    this.description,
    required this.icon,
    this.color,
    required this.defaultSize,
    required this.supportedSizes,
    required this.category,
    required this.builder,
    this.availableStatsProvider,
    // 选择器相关
    this.selectorId,
    this.dataRenderer,
    this.navigationHandler,
    this.dataSelector,
  });

  /// 构建小组件
  ///
  /// 注意：config 中会自动注入 'widgetSize' 字段，表示当前小组件尺寸
  Widget build(BuildContext context, Map<String, dynamic> config, [HomeWidgetSize? size]) {
    // 将尺寸信息注入 config，供 builder 使用
    final effectiveConfig = size != null ? {...config, 'widgetSize': size} : config;
    return builder(context, effectiveConfig);
  }

  /// 是否支持指定尺寸
  bool supportsSize(HomeWidgetSize size) {
    return supportedSizes.contains(size);
  }

  /// 是否为选择器小组件
  bool get isSelectorWidget => selectorId != null;
}
