import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

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

/// 公共小组件提供者函数类型
///
/// 插件可以定义此函数，根据选择的数据返回可用的公共小组件及其 props 配置
///
/// 参数：
/// - data: 从数据选择器获取并处理后的数据（Map 格式）
///
/// 返回：
/// - Map<公共小组件ID, Props配置>：每个公共小组件及其对应的 props
///
/// 示例：
/// ```dart
/// commonWidgetsProvider: (data) {
///   return {
///     'circularProgressCard': {
///       'title': data['title'],
///       'subtitle': '${data['count']} 条消息',
///       'percentage': (data['count'] / 100 * 100).clamp(0, 100),
///       'progress': (data['count'] / 100).clamp(0.0, 1.0),
///     },
///     'activityProgressCard': {
///       'title': data['title'],
///       'subtitle': '今日活动',
///       'value': data['count'].toDouble(),
///       'unit': '个',
///       'activities': data['count'],
///       'totalProgress': 10,
///       'completedProgress': data['count'] % 10,
///     },
///   };
/// }
/// ```
typedef CommonWidgetsProvider = Future<Map<String, Map<String, dynamic>>> Function(
  Map<String, dynamic> data,
);

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

  /// 支持的尺寸列表（可选，默认为所有支持的尺寸）
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

  // ===== 公共小组件相关字段（可选） =====

  /// 公共小组件提供者（可选）
  ///
  /// 如果提供，该小组件支持适配公共小组件
  /// 用户在选择数据后，可以选择使用哪个公共小组件来渲染
  ///
  /// 函数接收处理后的数据，返回可用的公共小组件 ID 及其 props 配置
  final CommonWidgetsProvider? commonWidgetsProvider;

  const HomeWidget({
    required this.id,
    required this.pluginId,
    required this.name,
    this.description,
    required this.icon,
    this.color,
    required this.defaultSize,
    this.supportedSizes = const [],
    required this.category,
    required this.builder,
    this.availableStatsProvider,
    // 选择器相关
    this.selectorId,
    this.dataRenderer,
    this.navigationHandler,
    this.dataSelector,
    // 公共小组件相关
    this.commonWidgetsProvider,
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
  ///
  /// 如果 supportedSizes 为空，则检查所有支持的尺寸
  bool supportsSize(HomeWidgetSize size) {
    return effectiveSupportedSizes.contains(size) ||
        (size is CustomSize && supportedSizes.isEmpty);  // 空列表时支持任何自定义尺寸
  }

  /// 获取有效的支持的尺寸列表
  ///
  /// 如果 supportedSizes 为空，返回所有支持的尺寸（包括自定义尺寸）
  List<HomeWidgetSize> get effectiveSupportedSizes =>
      supportedSizes.isEmpty ? HomeWidgetSize.allSupportedSizes : supportedSizes;

  /// 是否为选择器小组件
  bool get isSelectorWidget => selectorId != null;

  /// 是否支持公共小组件
  bool get supportsCommonWidgets => commonWidgetsProvider != null;

  // ===== 通用构建方法 =====

  /// 构建错误提示组件
  static Widget buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// 构建未配置状态的占位小组件
  static Widget buildUnconfiguredWidget(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '点击配置',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建默认的已配置视图（当未使用公共小组件时）
  static Widget buildDefaultConfiguredWidget(
    BuildContext context,
    SelectorResult result,
    HomeWidget widgetDefinition,
  ) {
    final theme = Theme.of(context);
    final color = widgetDefinition.color ?? theme.colorScheme.primary;

    // 尝试从 result.data 获取标题
    String title = '已配置';
    String? subtitle;

    if (result.data is Map) {
      final dataMap = result.data as Map;
      title = dataMap['title']?.toString() ?? title;
      subtitle = dataMap['subtitle']?.toString() ?? dataMap['url']?.toString();
    } else if (result.path.isNotEmpty) {
      title = result.path.last.selectedItem.title;
      subtitle = result.path.last.selectedItem.subtitle;
    }

    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widgetDefinition.icon, size: 24, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widgetDefinition.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建动态公共小组件（每次渲染都重新获取最新数据）
  static Widget buildDynamicCommonWidget(
    BuildContext context,
    SelectorWidgetConfig selectorConfig,
    HomeWidget widgetDefinition,
    Map<String, dynamic> config,
  ) {
    try {
      final widgetId = selectorConfig.commonWidgetId!;
      final size =
          config['widgetSize'] as HomeWidgetSize? ??
          widgetDefinition.defaultSize;

      // 将字符串 ID 转换为枚举值
      final commonWidgetId = CommonWidgetsRegistry.fromString(widgetId);
      if (commonWidgetId == null) {
        return buildErrorWidget(context, '未知的公共组件: $widgetId');
      }

      // 获取原始数据（从 selectorConfig.selectedData）
      final selectedData = selectorConfig.selectedData;
      if (selectedData == null) {
        return buildErrorWidget(context, '无法获取选择的数据');
      }

      // 从 selectedData 中提取实际的数据数组
      Map<String, dynamic> data = {};
      if (selectedData.containsKey('data')) {
        final dataArray = selectedData['data'];
        if (dataArray is List && dataArray.isNotEmpty) {
          final rawData = dataArray[0];
          if (rawData is Map<String, dynamic>) {
            data = rawData;
          } else if (rawData != null && rawData is Map) {
            data = Map<String, dynamic>.from(rawData);
          }
        }
      }

      // 优先使用已保存的 commonWidgetProps（用户在对话框中选择的数据）
      // 只有当 props 不存在时才动态调用 commonWidgetsProvider 获取最新数据
      if (selectorConfig.commonWidgetProps != null) {
        // 使用用户在【公共组件样式】对话框中选择并保存的数据
        // 添加 custom 尺寸的实际宽高到 props 中
        final props = Map<String, dynamic>.from(selectorConfig.commonWidgetProps!);
        if (size == const CustomSize(width: -1, height: -1)) {
          props['customWidth'] = config['customWidth'] as int?;
          props['customHeight'] = config['customHeight'] as int?;
        }
        return CommonWidgetBuilder.build(
          context,
          commonWidgetId,
          props,
          size,
          inline: true,
        );
      }

      // 兼容旧数据：如果没有保存的 props，才动态获取
      if (widgetDefinition.commonWidgetsProvider != null) {
        // 使用 FutureBuilder 处理异步调用
        return FutureBuilder<Map<String, Map<String, dynamic>>>(
          future: widgetDefinition.commonWidgetsProvider!(data),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return buildErrorWidget(context, '加载组件数据失败');
            }

            final availableWidgets = snapshot.data ?? {};
            final latestProps = availableWidgets[widgetId];

            if (latestProps != null) {
              // 添加 custom 尺寸的实际宽高到 props 中
              final props = Map<String, dynamic>.from(latestProps);
              if (size == const CustomSize(width: -1, height: -1)) {
                props['customWidth'] = config['customWidth'] as int?;
                props['customHeight'] = config['customHeight'] as int?;
              }
              return CommonWidgetBuilder.build(
                context,
                commonWidgetId,
                props,
                size,
                inline: true,
              );
            }

            return buildErrorWidget(context, '无法获取最新数据');
          },
        );
      }

      return buildErrorWidget(context, '无法获取最新数据');
    } catch (e) {
      debugPrint('[HomeWidget] 构建公共组件失败: $e');
      return buildErrorWidget(context, '渲染公共组件失败');
    }
  }

  /// 构建动态选择器小组件（支持事件触发时重新获取数据）
  static Widget buildDynamicSelectorWidget(
    BuildContext context,
    Map<String, dynamic> config,
    HomeWidget widgetDefinition,
  ) {
    // 解析选择器配置
    SelectorWidgetConfig? selectorConfig;
    try {
      if (config.containsKey('selectorWidgetConfig')) {
        selectorConfig = SelectorWidgetConfig.fromJson(
          config['selectorWidgetConfig'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[HomeWidget] 解析配置失败: $e');
    }

    // 判断是否已配置
    if (selectorConfig == null || !selectorConfig.isConfigured) {
      return buildUnconfiguredWidget(context);
    }

    // 检查是否使用了公共小组件
    if (selectorConfig.usesCommonWidget) {
      return buildDynamicCommonWidget(
        context,
        selectorConfig,
        widgetDefinition,
        config,
      );
    }

    // 恢复 SelectorResult 并显示默认视图
    final originalResult = selectorConfig.toSelectorResult();
    if (originalResult == null) {
      return buildErrorWidget(context, '无法解析选择的数据');
    }

    return buildDefaultConfiguredWidget(
      context,
      originalResult,
      widgetDefinition,
    );
  }
}
