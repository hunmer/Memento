/// 物品管理插件 - 物品列表小组件注册
///
/// 注册物品列表小组件，支持仓库、标签、购入日期、过期日期过滤
library;

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
import 'utils.dart' show goodsColor;
import 'providers.dart';

/// 注册物品列表小组件
void registerGoodsListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'goods_list_widget',
      pluginId: 'goods',
      name: 'goods_listWidgetName'.tr,
      description: 'goods_listWidgetDescription'.tr,
      icon: Icons.view_list,
      color: goodsColor,
      defaultSize: const LargeSize(),
      supportedSizes: [const CustomSize(width: -1, height: -1), const LargeSize()],
      category: 'home_categoryRecord'.tr,

      // 选择器配置
      selectorId: 'goods.list.config',

      // 公共组件提供者（用于配置时预览）
      commonWidgetsProvider: provideGoodsListWidgets,

      // 导航处理器：点击时打开物品列表页面
      navigationHandler: _navigateToGoodsList,

      // 数据选择器：提取过滤器参数
      dataSelector: _extractFilterData,

      builder: (context, config) {
        return _GoodsListWidgetBuilder(
          widgetDefinition: registry.getWidget('goods_list_widget')!,
          config: config,
        );
      },
    ),
  );
}

/// 导航到物品列表页面
void _navigateToGoodsList(
  BuildContext context,
  SelectorResult result,
) {
  final data = result.data as Map<String, dynamic>?;
  if (data == null) {
    debugPrint('[GoodsListWidget] 过滤器数据为空');
    return;
  }

  // 获取过滤器参数
  final warehouseId = data['warehouseId'] as String?;
  final tags = data['tags'] as List<dynamic>?;
  final startDate = data['startDate'] as String?;
  final endDate = data['endDate'] as String?;

  // 导航到物品列表页面，传递过滤器参数
  NavigationHelper.pushNamed(
    context,
    '/goods',
    arguments: {
      'filterWarehouseId': warehouseId,
      'filterTags': tags,
      'filterStartDate': startDate,
      'filterEndDate': endDate,
      'showGoodsTab': true, // 显示物品标签页而不是仓库标签页
    },
  );
}

/// 提取过滤器数据
Map<String, dynamic> _extractFilterData(List<dynamic> data) {
  // 数据格式为 [{warehouseId: ..., tags: [...], startDate: ..., endDate: ...}]
  if (data.isEmpty) return {};
  final item = data.first as Map<String, dynamic>;
  return item;
}

/// 物品列表小组件构建器
///
/// 使用 EventListenerContainer 监听数据变化，每次重建时从插件获取最新数据
class _GoodsListWidgetBuilder extends StatelessWidget {
  final HomeWidget widgetDefinition;
  final Map<String, dynamic> config;

  const _GoodsListWidgetBuilder({
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
      debugPrint('[GoodsListWidget] 解析配置失败: $e');
    }

    // 未配置状态
    if (selectorConfig == null || !selectorConfig.isConfigured) {
      return _buildUnconfiguredWidget(context);
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const ['goods_item_added', 'goods_item_deleted'],
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
      future: provideGoodsListWidgets(config),
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
              Icons.inventory_2_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'goods_noItems'.tr,
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
