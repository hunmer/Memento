/// 聊天插件 - 频道选择器组件注册
///
/// 注册频道选择器组件，支持快速访问指定频道和公共小组件
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'builders.dart';
import 'providers.dart';

/// 注册聊天频道选择器组件
///
/// 支持快速访问指定频道，并提供公共小组件功能
void registerChannelSelector(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'chat_channel_selector',
      pluginId: 'chat',
      name: 'chat_channelQuickAccess'.tr,
      description: 'chat_channelQuickAccessDesc'.tr,
      icon: Icons.chat,
      color: Colors.indigoAccent,
      defaultSize: const LargeSize(),
      category: 'home_categoryCommunication'.tr,

      selectorId: 'chat.channel',
      dataRenderer: renderChannelData,
      navigationHandler: navigateToChannel,
      dataSelector: extractChannelData,

      // 公共小组件提供者
      commonWidgetsProvider: provideCommonWidgets,

      builder: (context, config) {
        // 使用 StatefulBuilder 实现实时数据获取
        return StatefulBuilder(
          builder: (context, setState) {
            return EventListenerContainer(
              events: const ['chat_message_sent', 'chat_message_updated'],
              onEvent: () => setState(() {}),
              child: _ChannelSelectorWidget(
                config: config,
                widgetDefinition: registry.getWidget('chat_channel_selector')!,
              ),
            );
          },
        );
      },
    ),
  );
}

/// 内部组件
class _ChannelSelectorWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final HomeWidget widgetDefinition;

  const _ChannelSelectorWidget({
    required this.config,
    required this.widgetDefinition,
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
      debugPrint('[ChatChannelSelector] 解析配置失败: $e');
    }

    // 未配置状态
    if (selectorConfig == null || !selectorConfig!.isConfigured) {
      return HomeWidget.buildUnconfiguredWidget(context);
    }

    // 检查是否使用了公共小组件
    if (selectorConfig!.usesCommonWidget) {
      return _buildCommonWidgetWithLiveData(context, selectorConfig!);
    }

    // 默认视图（使用 dataRenderer）
    final originalResult = selectorConfig!.toSelectorResult();
    if (originalResult == null) {
      return HomeWidget.buildErrorWidget(context, '无法解析选择的数据');
    }

    return renderChannelData(context, originalResult, config);
  }

  /// 使用实时数据构建公共小组件
  Widget _buildCommonWidgetWithLiveData(
    BuildContext context,
    SelectorWidgetConfig selectorConfig,
  ) {
    final commonWidgetId = selectorConfig.commonWidgetId;
    final selectedData = selectorConfig.selectedData;
    if (selectedData == null) {
      return HomeWidget.buildErrorWidget(context, '配置数据无效');
    }

    // 获取频道ID
    final data = selectedData['data'];
    String? channelId;
    if (data is Map<String, dynamic>) {
      channelId = data['id'] as String?;
    } else if (data is List && data.isNotEmpty) {
      final firstItem = data[0];
      if (firstItem is Map<String, dynamic>) {
        channelId = firstItem['id'] as String?;
      }
    }

    if (channelId == null) {
      return HomeWidget.buildErrorWidget(context, 'chat_channelNotFound'.tr);
    }

    // 获取实时频道数据
    final liveData = getLiveChannelData(channelId);
    if (liveData == null) {
      return HomeWidget.buildErrorWidget(context, 'chat_channelNotFound'.tr);
    }

    // 转换为枚举
    final widgetIdEnum = CommonWidgetsRegistry.fromString(commonWidgetId ?? '');
    if (widgetIdEnum == null) {
      return HomeWidget.buildErrorWidget(context, '未知的公共组件: $commonWidgetId');
    }

    // 获取尺寸
    final size = config['widgetSize'] as HomeWidgetSize? ??
        widgetDefinition.defaultSize;

    // 使用实时数据更新 props
    final liveProps = getLiveCommonWidgetProps(
      commonWidgetId ?? '',
      liveData,
      selectorConfig.commonWidgetProps ?? {},
    );

    // 添加 custom 尺寸的实际宽高到 props 中
    if (size == const CustomSize(width: -1, height: -1)) {
      liveProps['customWidth'] = config['customWidth'] as int?;
      liveProps['customHeight'] = config['customHeight'] as int?;
    }

    return EventListenerContainer(
      events: const ['chat_message_sent', 'chat_message_updated'],
      onEvent: () {},
      child: CommonWidgetBuilder.build(
        context,
        widgetIdEnum,
        liveProps,
        size,
        inline: true,
      ),
    );
  }
}
