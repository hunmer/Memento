library;

/// 账单插件 - 支出统计组件注册

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'bill_colors.dart';
import 'providers.dart' show provideBillStatsWidgets;

/// 注册支出统计组件
void registerBillStatsWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'bill_stats_widget',
      pluginId: 'bill',
      name: 'bill_statsWidgetName'.tr,
      description: 'bill_statsWidgetDescription'.tr,
      icon: Icons.pie_chart,
      color: billColor,
      defaultSize: const LargeSize(),
      supportedSizes: [
        const MediumSize(),
        const LargeSize(),
        const CustomSize(width: -1, height: -1),
      ],
      category: 'home_categoryRecord'.tr,

      // 选择器配置
      selectorId: 'bill.stats.config',

      // 公共组件提供者（用于配置时预览）
      commonWidgetsProvider: provideBillStatsWidgets,

      // 导航处理器：点击时打开账单统计页面
      navigationHandler: _navigateToBillStats,

      // 数据选择器：提取配置参数
      dataSelector: _extractConfigData,

      builder: (context, config) {
        return _BillStatsWidgetBuilder(
          widgetDefinition: registry.getWidget('bill_stats_widget')!,
          config: config,
        );
      },
    ),
  );
}

/// 导航到账单统计页面
void _navigateToBillStats(
  BuildContext context,
  SelectorResult result,
) {
  final data = result.data as Map<String, dynamic>?;
  if (data == null) {
    debugPrint('[BillStatsWidget] 配置数据为空');
    return;
  }

  // 获取配置参数
  final type = data['type'] as String?;
  final startDate = data['startDate'] as String?;
  final endDate = data['endDate'] as String?;

  // 导航到账单页面，传递统计参数
  NavigationHelper.pushNamed(
    context,
    '/bill',
    arguments: {
      'showStatsTab': true, // 显示统计标签页
      'statsType': type ?? 'expense',
      'statsStartDate': startDate,
      'statsEndDate': endDate,
    },
  );
}

/// 提取配置数据
Map<String, dynamic> _extractConfigData(List<dynamic> data) {
  // 数据格式为 [{type: ..., startDate: ..., endDate: ..., targetAmount: ...}]
  if (data.isEmpty) return {};
  final item = data.first as Map<String, dynamic>;
  return item;
}

/// 账单统计小组件构建器
///
/// 使用 EventListenerContainer 监听数据变化，每次重建时从插件获取最新数据
class _BillStatsWidgetBuilder extends StatelessWidget {
  final HomeWidget widgetDefinition;
  final Map<String, dynamic> config;

  const _BillStatsWidgetBuilder({
    required this.widgetDefinition,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // 解析选择器配置
    SelectorWidgetConfig? selectorConfig;
    try {
      if (config.containsKey('selectorWidgetConfig')) {
        selectorConfig = SelectorWidgetConfig.fromJson(
          config['selectorWidgetConfig'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[BillStatsWidget] 解析配置失败: $e');
    }

    // 未配置状态
    if (selectorConfig == null || !selectorConfig.isConfigured) {
      return _buildUnconfiguredWidget(context);
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'bill_added',
            'bill_deleted',
            'account_added',
            'account_deleted',
          ],
          onEvent: () => setState(() {}),
          child: _buildSelectorContent(context, config, selectorConfig!),
        );
      },
    );
  }

  /// 构建选择器内容（每次重建时获取最新数据）
  Widget _buildSelectorContent(
    BuildContext context,
    Map<String, dynamic> config,
    SelectorWidgetConfig selectorConfig,
  ) {
    // 检查是否使用公共小组件
    if (selectorConfig.usesCommonWidget) {
      return _buildCommonWidgetWithLiveData(
        context,
        config,
        selectorConfig.commonWidgetId!,
        selectorConfig.commonWidgetProps ?? {},
      );
    }

    // 默认视图（使用 dataRenderer）
    return GenericSelectorWidget(
      widgetDefinition: widgetDefinition,
      config: config,
    );
  }

  /// 使用实时数据构建公共小组件
  Widget _buildCommonWidgetWithLiveData(
    BuildContext context,
    Map<String, dynamic> config,
    String commonWidgetId,
    Map<String, dynamic> savedProps,
  ) {
    // 每次重建时异步获取实时数据
    return FutureBuilder<Map<String, dynamic>>(
      future: provideBillStatsWidgets(config),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget(context);
        }

        if (snapshot.hasError) {
          return HomeWidget.buildErrorWidget(context, snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWidget(context);
        }

        // 从配置中获取 widgetSize
        final size = config['widgetSize'] as HomeWidgetSize? ??
            widgetDefinition.defaultSize;

        // 将字符串 ID 转换为枚举值
        final commonWidgetIdEnum = CommonWidgetsRegistry.fromString(commonWidgetId);
        if (commonWidgetIdEnum == null) {
          return HomeWidget.buildErrorWidget(context, '未知的公共组件: $commonWidgetId');
        }

        // 使用实时数据（从 provider 返回的数据中获取对应的小组件数据）
        final liveData = snapshot.data![commonWidgetId] as Map<String, dynamic>?;

        if (liveData == null) {
          return HomeWidget.buildErrorWidget(context, '数据不存在');
        }

        // 合并保存的配置和实时数据
        final liveProps = _mergeProps(savedProps, liveData);

        // 添加 custom 尺寸的实际宽高到 props 中
        final finalProps = Map<String, dynamic>.from(liveProps);
        if (size == const CustomSize(width: -1, height: -1)) {
          finalProps['customWidth'] = config['customWidth'] as int?;
          finalProps['customHeight'] = config['customHeight'] as int?;
        }

        return CommonWidgetBuilder.build(
          context,
          commonWidgetIdEnum,
          finalProps,
          size,
          inline: true,
        );
      },
    );
  }

  /// 合并保存的配置和实时数据
  Map<String, dynamic> _mergeProps(
    Map<String, dynamic> savedProps,
    Map<String, dynamic> liveData,
  ) {
    // 实时数据优先覆盖保存的配置
    return {
      ...savedProps,
      ...liveData,
    };
  }

  /// 构建加载状态
  Widget _buildLoadingWidget(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyWidget(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无账单',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建未配置状态的占位小组件
  Widget _buildUnconfiguredWidget(BuildContext context) {
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
}
