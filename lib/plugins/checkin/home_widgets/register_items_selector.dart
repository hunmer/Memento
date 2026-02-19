/// 打卡插件 - 多选签到项目小组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'providers.dart';
import 'utils.dart';

/// 注册多选签到项目小组件 - 显示多个签到项目的打卡状态
void registerItemsSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'checkin_items_selector',
      pluginId: 'checkin',
      name: 'checkin_multiQuickAccess'.tr,
      description: 'checkin_multiQuickAccessDesc'.tr,
      icon: Icons.dashboard,
      color: Colors.teal,
      defaultSize: const LargeSize(),
      supportedSizes: [
        const LargeSize(),
        const CustomSize(width: -1, height: -1),
      ],
      category: 'home_categoryRecord'.tr,
      selectorId: 'checkin.items',
      navigationHandler: _navigateToCheckinItems,
      dataSelector: extractCheckinsData,
      // 公共小组件提供者
      commonWidgetsProvider: provideCommonWidgetsForMultiple,
      builder: (context, config) {
        // 使用自定义 StatefulWidget 实现实时数据获取
        return _CheckinItemsSelectorWidget(
          config: config,
          widgetDefinition: registry.getWidget('checkin_items_selector')!,
        );
      },
    ),
  );
}

/// 导航到签到项目列表（多选模式）
void _navigateToCheckinItems(BuildContext context, SelectorResult result) {
  // 多选模式默认导航到签到主列表
  NavigationHelper.pushNamed(context, '/checkin');
}

/// 内部 StatefulWidget 用于持有配置并实现实时数据获取
class _CheckinItemsSelectorWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final HomeWidget widgetDefinition;

  const _CheckinItemsSelectorWidget({
    required this.config,
    required this.widgetDefinition,
  });

  @override
  State<_CheckinItemsSelectorWidget> createState() =>
      _CheckinItemsSelectorWidgetState();
}

class _CheckinItemsSelectorWidgetState
    extends State<_CheckinItemsSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    // 解析选择器配置
    SelectorWidgetConfig? selectorConfig;
    try {
      if (widget.config.containsKey('selectorWidgetConfig')) {
        selectorConfig = SelectorWidgetConfig.fromJson(
          widget.config['selectorWidgetConfig'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[CheckinItemsSelector] 解析配置失败: $e');
    }

    // 未配置状态
    if (selectorConfig == null || !selectorConfig.isConfigured) {
      return HomeWidget.buildUnconfiguredWidget(context);
    }

    // 检查是否使用了公共小组件
    if (selectorConfig.usesCommonWidget) {
      return _buildCommonWidget(context, selectorConfig);
    }

    // 恢复 SelectorResult 并显示默认视图
    final originalResult = selectorConfig.toSelectorResult();
    if (originalResult == null) {
      return HomeWidget.buildErrorWidget(context, '无法解析选择的数据');
    }

    return EventListenerContainer(
      events: const [
        'checkin_completed',
        'checkin_cancelled',
        'checkin_reset',
        'checkin_deleted',
      ],
      onEvent: () => setState(() {}),
      child: HomeWidget.buildDefaultConfiguredWidget(
        context,
        originalResult,
        widget.widgetDefinition,
      ),
    );
  }

  /// 构建公共小组件（实时数据模式）
  Widget _buildCommonWidget(
    BuildContext context,
    SelectorWidgetConfig selectorConfig,
  ) {
    final commonWidgetId = selectorConfig.commonWidgetId!;
    final size =
        widget.config['widgetSize'] as HomeWidgetSize? ??
        widget.widgetDefinition.defaultSize;

    // 获取元数据
    final widgetIdEnum = CommonWidgetsRegistry.fromString(commonWidgetId);
    if (widgetIdEnum == null) {
      return HomeWidget.buildErrorWidget(context, '未知的公共组件: $commonWidgetId');
    }

    final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);

    return EventListenerContainer(
      events: const [
        'checkin_completed',
        'checkin_cancelled',
        'checkin_reset',
        'checkin_deleted',
      ],
      onEvent: () => setState(() {}),
      child: _buildCommonWidgetContent(
        context,
        selectorConfig,
        widgetIdEnum,
        size,
        metadata,
      ),
    );
  }

  /// 构建公共小组件内容（使用保存的 props，不依赖 provider）
  Widget _buildCommonWidgetContent(
    BuildContext context,
    SelectorWidgetConfig selectorConfig,
    CommonWidgetId widgetIdEnum,
    HomeWidgetSize size,
    CommonWidgetMetadata metadata,
  ) {
    // 优先使用保存的 commonWidgetProps（用户在选择器对话框中选择的数据）
    if (selectorConfig.commonWidgetProps != null) {
      final props = Map<String, dynamic>.from(selectorConfig.commonWidgetProps!);

      // 添加 custom 尺寸的实际宽高到 props 中
      if (size == const CustomSize(width: -1, height: -1)) {
        props['customWidth'] = widget.config['customWidth'] as int?;
        props['customHeight'] = widget.config['customHeight'] as int?;
      }

      return CommonWidgetBuilder.build(
        context,
        widgetIdEnum,
        props,
        size,
        inline: true,
      );
    }

    // 如果没有保存的 props，尝试动态获取（兼容旧数据）
    final selectedData = selectorConfig.selectedData;
    if (selectedData == null) {
      return HomeWidget.buildErrorWidget(context, '无法获取选择的数据');
    }

    // 从 selectedData 中提取实际的数据数组
    Map<String, dynamic> data = {};
    if (selectedData.containsKey('data')) {
      final dataArray = selectedData['data'];
      if (dataArray is List && dataArray.isNotEmpty) {
        // 对于多选情况，使用 items 格式
        data = {'items': List<Map<String, dynamic>>.from(dataArray)};
      }
    }

    if (widget.widgetDefinition.commonWidgetsProvider != null) {
      return FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: widget.widgetDefinition.commonWidgetsProvider!(data),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return HomeWidget.buildErrorWidget(context, '加载组件数据失败');
          }

          final availableWidgets = snapshot.data ?? {};
          final latestProps = availableWidgets[widgetIdEnum.name];

          if (latestProps == null) {
            return HomeWidget.buildErrorWidget(
              context,
              '未知的公共组件类型: ${widgetIdEnum.name}',
            );
          }

          // 添加 custom 尺寸的实际宽高到 props 中
          final props = Map<String, dynamic>.from(latestProps);
          if (size == const CustomSize(width: -1, height: -1)) {
            props['customWidth'] = widget.config['customWidth'] as int?;
            props['customHeight'] = widget.config['customHeight'] as int?;
          }

          return CommonWidgetBuilder.build(
            context,
            widgetIdEnum,
            props,
            size,
            inline: true,
          );
        },
      );
    }

    return HomeWidget.buildErrorWidget(context, '无法加载组件数据');
  }
}
